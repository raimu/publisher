title: Configuration file
---
How to configure the speedata publisher
=======================================

The speedata publisher can be configured in several ways:

1.  The file `publisher.cfg` in `/etc/speedata/`, in the home directory
    (with a leading dot) and in the current working directory
2.  Parameters given on the command line
3.  Options given in the layout file

The file `publisher.cfg`
------------------------

The file `publisher.cfg` (`/etc/speedata/publisher.cfg`,
`$HOME/.publisher.cfg` and in the current working directory) is a text
file, that is read at the beginning of the publisher run. The default
file looks like this:

    data      = data.xml
    layout    = layout.xml
    autoopen  = false

The format of the file is important, otherwise it won’t be recognized.
The following options are supported:

Value | Description
------|------------
`autoopen` | if `true`, the publisher opens the PDF file. Default: `false`. The  same effect can be achieved if you run `sp --autoopen`.
`data` | Name of the data file (XML). If not given, the system uses `data.xml`.
`dummy` | If `true`, the system won’t read the data file, instead it uses the single element `<data />` as its input.
`extra-dir` | A list of directories in the file system separated by `;` (Windows) or `:` (Mac, Linux). These directories contain the images, fonts, source files and other assets that are used during the publisher run.
`filter` | Run the given file as an XPROC-Filter.
`fontpath` | Set the path for system fonts. On Windows this is `%WINDIR%\Fonts`, on Mac OS X it defaults to `/Library/Fonts:/System/Library/Fonts`.
`grid` | If `true`, the underlying grid is shown in the PDF file. For debugging purpose only.
`imagecache` | Folder for cached images (`href="http://..."` only). Defaults to `$TMPDIR/sp/images`.
`jobname` | Name of the output file. Default is `publisher`.
`layout` | Name of the layout rule set (XML). The default name is `layout.xml`.
`opencommand` | Command that will be run to open the documentation and the PDF file. For MacOS X this should be `open`, for Linux `xdg-open` or `exo-open` (xfce).
`pathrewrite` | Comma separated list of entries of the form `A=B` which replace parts in `file:///...A...` to `file:///...B...`. Useful when you have absolute paths in the data which must be changed during the publishing process.
`runs` | Set the number of runs.
`startpage` | Number of the first page.
`timeout` | Maximum time of the publishing run. If time is exceeded, the publisher exits with status 1.

You can access the base directory of the project with `%(projectdir)s`.
This is the directory with the file `publisher.cfg`.

All entries in the configuration file are optional. The configuration
files are read in the following order: `/etc/speedata/publisher.cfg`,
`~/.publisher.cfg` and in the current directory `publisher.cfg`. The
current directory can be changed on the command line with the switch
`--wd=....`.

Command line parameters
-----------------------

The valid command line parameters are written on a [separate
page](commandline.html).

Options given in the layout file
--------------------------------

The XML layout file has a command called
[Options](../commands-en/options.html) that allows to set some
parameters (tracing, default language, …)
