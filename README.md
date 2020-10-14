# kazuyo

This simple script is going to tidy photo files into date directory hierarchy like ``yyyy/mm/yyyymmdd/image.jpg``. Also, check for duplicate photo files, and if duplicates are found, gather them in the ``duplicate/`` directory.

## Getting Started

1. clone this repository

```bash
$ git clone https://github.com/ontheroadjp/kazuyo/tree/dev
```

2. go into kazuyo

```bash
$ cd kazuyo
```

3. Run ``checkup`` command to analyse directory which contains photo files are going to tidy.

```bash
$ sh kazuyo checkup <dir>
```

4. run tidy command to tidy photo

```bash
$ kazuyo tidy <dir>
```

