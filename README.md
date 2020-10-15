# kazuyo

This simple script is going to tidy photo files into date directory hierarchy like ``yyyy/mm/yyyymmdd/image.jpg``. Also, check for duplicate photo files, and if duplicates are found, gather them in the ``duplicate/`` directory.

## Install

1. clone this repository

```bash
$ git clone https://github.com/ontheroadjp/kazuyo/tree/dev
```

2. Execute the following command according to the type of shell

```bash
# for bash
echo "export PATH="path/to/kazuyo:${PATH}" >> ~/.bash_profile

# for zsh
echo "export PATH="path/to/kazuyo:${PATH}" >> ~/.zprofile
```

3. Finish



## Quick Start

1. Run ``kazuyo init`` command to analyse directory which contains photo files are going to tidy.

```bash
$ kazuyo init [target directory]
```

2. Run ``kazuyo tidy`` command to tidy photo files. 

When you execute the command, a dist directory is created in [target directory], and it is organized in the directory hierarchy according to the date.

```bash
$ sh kazuyo tidy [target directory]
```



