package gomddoc

import (
	"bytes"
	"encoding/xml"
	"errors"
	"fmt"
	"github.com/gorilla/feeds"
	"github.com/speedata/blackfriday"
	"io/ioutil"
	"log"
	"os"
	"path"
	"path/filepath"
	"regexp"
	"strings"
	"text/template"
	"time"
)

var (
	key_value_regexp *regexp.Regexp
	templates        *template.Template
	ignoredFiles     map[string]bool
)

type clText struct {
	Text string `xml:",innerxml"`
}

type clEntry struct {
	Version string `xml:"version,attr"`
	Date    string `xml:"date,attr"`
	En      clText `xml:"en"`
	De      clText `xml:"de"`
}

type clChapter struct {
	Version string    `xml:"version,attr"`
	Entries []clEntry `xml:"entry"`
}

type changelog struct {
	Chapter []clChapter `xml:"chapter"`
}

type MDDoc struct {
	Version   string
	root      string
	basedir   string
	assets    string
	dest      string
	changelog *changelog
	renderer  blackfriday.Renderer
}

func init() {
	// `foo: bar' like key value lines
	key_value_regexp = regexp.MustCompile(`^([^:]+):\s*(.*)$`)
	ignoredFiles = map[string]bool{
		".DS_Store":  true,
		"index.md":   true,
		".gitignore": true,
	}
}

func parseChangelog(filename string) *changelog {
	data, err := ioutil.ReadFile(filename)
	if err != nil {
		log.Fatal(err)
	}
	cl := &changelog{}
	err = xml.Unmarshal(data, cl)
	if err != nil {
		log.Fatal(err)
	}
	return cl
}

// rootdir is the directory with the documents (subdir doc/) and the css/js etc (assets/).
// destdir is where the documentation should be placed in,
// basedir is the the installation with the template directory
func NewMDDoc(rootdir, destdir, basedir, changelogpath string) (*MDDoc, error) {
	var directoriesNotSet []string

	if basedir == "" {
		directoriesNotSet = append(directoriesNotSet, "base directory")
	}
	if rootdir == "" {
		directoriesNotSet = append(directoriesNotSet, "root directory")
	}
	if destdir == "" {
		directoriesNotSet = append(directoriesNotSet, "dest directory")
	}
	if len(directoriesNotSet) > 0 {
		return nil, errors.New("Missing name of these directories:" + strings.Join(directoriesNotSet, ", "))
	}

	a := MDDoc{}
	a.root = rootdir
	a.dest = destdir
	a.basedir = basedir
	a.changelog = parseChangelog(changelogpath)
	a.assets = filepath.Join(basedir, "assets")
	a.renderer = blackfriday.HtmlRenderer(0, "", "")
	return &a, nil
}

func (md *MDDoc) getRootDir(context htmlTemplateData) string {
	path_elements := strings.Split(strings.TrimPrefix(context.Sourcefilename, md.dest+"/"), "/")
	return strings.Repeat("../", len(path_elements)-1)
}

func (md *MDDoc) getAssetsDir(context htmlTemplateData) string {
	path_elements := strings.Split(strings.TrimPrefix(context.Sourcefilename, md.dest+"/"), "/")
	return strings.Repeat("../", len(path_elements)-1) + "assets"
}

func (md *MDDoc) image(context mdTemplateData, imagename string) string {
	return fmt.Sprintf(`<a href="../img/%s"><img src="../img/%s"></a>`, imagename, imagename)
}

func (md *MDDoc) writeFeed(lang string) {
	feed := &feeds.Feed{
		Title:   fmt.Sprintf("speedata Publisher changelog (%s)", lang),
		Link:    &feeds.Link{Href: "http://www.speedata.de"},
		Author:  &feeds.Author{"speedata", "info@speedata.de"},
		Created: time.Now(),
	}
	if lang == "en" {
		feed.Description = "New revisions for download and changelog."
	} else {
		feed.Description = "Neue Versionen des Publishers zum Download und Liste der Änderungen"
	}
	feed.Items = make([]*feeds.Item, 0)
	for _, chap := range md.changelog.Chapter {
		for _, entry := range chap.Entries {
			i := &feeds.Item{}
			i.Title = "Version " + entry.Version
			t, err := time.Parse("2006-01-02", entry.Date)
			if err == nil {
				i.Created = t
			}
			if lang == "en" {
				i.Description = entry.En.Text
			} else {
				i.Description = entry.De.Text
			}
			i.Link = &feeds.Link{Href: "http://www.speedata.de"}

			feed.Items = append(feed.Items, i)
		}
	}
	atom, err := feed.ToAtom()
	if err != nil {
		log.Fatal(err)
	}
	ioutil.WriteFile(filepath.Join(md.dest, fmt.Sprintf("changes-%s.xml", lang)), []byte(atom), 0644)
}

// Generate the html documentation and copy all necessary assets to the build directory
func (md *MDDoc) DoThings() error {
	var err error
	funcMap := template.FuncMap{
		"rootDoc": md.rootDoc,
		"footer":  md.footerHTML,
		"assets":  md.getAssetsDir,
		"root":    md.getRootDir,
	}

	err = os.MkdirAll(md.dest, 0755)
	if err != nil {
		return err
	}

	// text.template because we trust the input...
	templates, err = template.New("").Funcs(funcMap).ParseGlob(filepath.Join(md.basedir, "templates", "*html"))
	if err != nil {
		return err
	}

	err = filepath.Walk(md.root, md.generateHTMLDocs)
	if err != nil {
		return err
	}

	md.writeFeed("en")
	md.writeFeed("de")
	return nil
}

func (md *MDDoc) generateHTMLDocs(path string, info os.FileInfo, err error) error {
	if filepath.Ext(path) == ".md" {
		md.convertToHTML(path)
	} else {
		return md.copyFile(path, info)
	}
	return nil
}

func (md *MDDoc) copyFile(path string, info os.FileInfo) error {
	path_without_prefix := strings.TrimPrefix(path, md.root)
	if info.IsDir() {
		os.Mkdir(filepath.Join(md.dest, path_without_prefix), 0755)
	} else {
		if ignoredFiles[filepath.Base(path)] {
			return nil
		}
		destpath := filepath.Join(md.dest, path_without_prefix)
		filecontents, err := ioutil.ReadFile(path)
		if err != nil {
			return err
		}
		err = ioutil.WriteFile(destpath, filecontents, 0644)
		if err != nil {
			return err
		}
	}
	return nil
}

type mdTemplateData struct {
	Changelog      *changelog
	Sourcefilename string
	KeyValue       map[string]string
	IsEn           bool
}

type htmlTemplateData struct {
	Title          string
	Contents       string
	Layout         string
	Sourcefilename string
	IsEn           bool
}

type mdFilelist struct {
	Filename    string
	Link        string
	Description string
}

// Return ../index.html except when the parent dir is the non-english main page
func (md *MDDoc) parentdir(context mdTemplateData) string {
	if strings.Count(context.Sourcefilename, "/") == 2 && strings.Contains(context.Sourcefilename, "-de") {
		return "../index-de.html"
	}
	return "../index.html"
}
func (md *MDDoc) filelist(context mdTemplateData) []mdFilelist {
	dir := filepath.Dir(context.Sourcefilename)
	matches, err := filepath.Glob(dir + "/*")
	if err != nil {
		log.Fatal(err)
	}
	var ret []mdFilelist
	for _, dir := range matches {
		fn := filepath.Base(dir)
		filename := mdFilelist{}

		fi, err := os.Stat(dir)
		if err != nil {
			log.Fatal(err)
		}
		if fi.IsDir() {
			filename.Link = path.Join(fn, "index.html")
		} else {
			filename.Link = fn
		}

		filename.Filename = fn
		filename.Description = context.KeyValue[fn]
		if !ignoredFiles[fn] {
			ret = append(ret, filename)
		}
	}
	return ret
}

func (md *MDDoc) convertToHTML(filename string) {
	f, err := ioutil.ReadFile(filename)
	if err != nil {
		log.Fatal(err)
	}

	// first, let's read the part at the top of the page to get the page title
	pos := bytes.Index(f, []byte{'\n', '-', '-', '-'})
	lines := strings.Split(string(f[:pos]), "\n")
	kv := make(map[string]string)
	for _, line := range lines {
		tmp := key_value_regexp.FindAllStringSubmatch(line, -1)
		if len(tmp) == 1 {
			kv[tmp[0][1]] = tmp[0][2]
		}
	}
	funcMap := template.FuncMap{
		"rootDoc":   md.rootDoc,
		"filelist":  md.filelist,
		"img":       md.image,
		"parentdir": md.parentdir,
	}

	// Now we can parse the template
	x := template.Must(template.New("name").Funcs(funcMap).Parse(string(f[pos+4:])))
	x.ParseGlob(filepath.Join(md.basedir, "templatesmd", "*.md"))

	dataMd := mdTemplateData{
		Changelog:      md.changelog,
		Sourcefilename: filename,
		KeyValue:       kv,
		IsEn:           isEn(filename),
	}

	bb := new(bytes.Buffer)
	err = x.Execute(bb, dataMd)
	if err != nil {
		log.Fatal(err)
	}

	out := blackfriday.Markdown(bb.Bytes(), md.renderer, blackfriday.EXTENSION_FENCED_CODE|blackfriday.EXTENSION_TABLES)

	extension := filepath.Ext(filename)
	basename := strings.TrimLeft(filename[0:len(filename)-len(extension)], md.root)
	outfilename := filepath.Join(md.dest, basename+".html")

	err = os.MkdirAll(filepath.Dir(outfilename), 0755)
	if err != nil {
		log.Fatal(err)
	}

	outfile, err := os.OpenFile(outfilename, os.O_CREATE|os.O_RDWR|os.O_TRUNC, 0644)
	if err != nil {
		log.Fatal(err)
	}

	data := htmlTemplateData{kv["title"], string(out), kv["layout"], outfilename, isEn(filename)}
	err = templates.ExecuteTemplate(outfile, "main.html", data)
	if err != nil {
		log.Fatal(err)
	}
}

func (md *MDDoc) pathToRoot(path string) string {
	path_without_prefix := strings.TrimPrefix(path, md.dest+"/")
	path_elements := strings.Split(path_without_prefix, "/")
	return strings.Repeat("../", len(path_elements)-1)
}

// Return a relative link to the other language (en <---> de)
func (md *MDDoc) otherLanguage(path string) string {
	switch strings.TrimPrefix(path, md.dest+"/") {
	case "index.html":
		return "index-de.html"
	case "index-de.html":
		return "index.html"
	}
	path_elements := strings.Split(strings.TrimPrefix(path, md.dest+"/"), "/")
	path_components := 0
	var paths []string

	for i, dir := range path_elements {
		if i == len(path_elements)-1 {
			paths = append(paths, dir)
		} else if i == 0 {
			if strings.Contains(dir, "-en") {
				paths = append(paths, strings.Replace(dir, "-en", "-de", -1))
			} else {
				paths = append(paths, strings.Replace(dir, "-de", "-en", -1))
			}
			path_components++
		} else {
			path_components++
			paths = append(paths, dir)
		}
	}
	paths_final := make([]string, path_components+len(paths))
	for i := 0; i < path_components; i++ {
		paths_final[i] = ".."
	}
	copy(paths_final[path_components:], paths)

	return filepath.Join(paths_final...)
}

func (md *MDDoc) footerHTML(path string) string {
	var clpart string
	if strings.HasSuffix(path, "description-en/changelog.html") {
		clpart = ` | <a href="../changes-en.xml">Changelog (atom feed)</a>`
	} else if strings.HasSuffix(path, "description-de/changelog.html") {
		clpart = ` | <a href="../changes-de.xml">Liste der Änderungen (atom feed)</a>`
	}
	if isEn(path) {
		return fmt.Sprintf(`Version: %s | <a href="%s">Start page</a> | <a href="%scommands-en/layout.html">Element reference</a> | Other language:  <a href="%s">German</a>%s`, md.Version, md.rootDoc(path), md.pathToRoot(path), md.otherLanguage(path), clpart)
	} else {
		return fmt.Sprintf(`Version: %s | <a href="%s">Startseite</a> | <a href="%scommands-de/layout.html">Elementreferenz</a> | Andere Sprache:  <a href="%s">Englisch</a>%s`, md.Version, md.rootDoc(path), md.pathToRoot(path), md.otherLanguage(path), clpart)
	}
}

func isEn(path string) bool {
	return !(strings.Contains(path, "-de/") || strings.Contains(path, "index-de.html"))
}

func (md *MDDoc) rootDoc(path string) string {
	if isEn(path) {
		return md.pathToRoot(path) + "index.html"
	} else {
		return md.pathToRoot(path) + "index-de.html"
	}
}
