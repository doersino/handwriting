# handwriting

A SQL implementation of an [ancient handwriting recognition algorithm](https://jackschaedler.github.io/handwriting-recognition/).

Yes, this is weird! But it nicely showcases that *SQL is a programming language*, which is the title of the [seminar](https://db.inf.uni-tuebingen.de/teaching/SQLisaProgrammingLanguageSS2018.html) during which this work was done.

**Overview:** The directory `code/` contains the implementation. In `paper/`, you'll find the LaTeX source of a short 4-page [term paper on the topic](paper/paper.pdf). Finally, a [Deckset](https://www.deckset.com/)-powered [set of slides](presentation/presentation.pdf) lives in `presentation/`.


## Setup

Install [PostgreSQL](https://www.postgresql.org/), version 10 or newer should work just fine. Then run:

```bash
psql -f code/handwriting_setup.sql
```


## Usage

Open `code/index.html` in your browser and draw a character as instructed. Ignore the "Working..." bit – setting up the server component, which runs the query on a background Postgres instance, can be a bit of a pain. Instead, copy the JSON value shown at the bottom of the page.

Change line 15 of `code/handwriting.sql` from

```sql
--\set pen '[ { "x": 37, "y": 31 }, { "x": 37, "y": 31 }, { "x": 37, "y": 34 }, { "x": 37, "y": 39 }, { "x": 38, "y": 43 }, { "x": 41, "y": 57 }, { "x": 44, "y": 66 }, { "x": 48, "y": 76 }, { "x": 52, "y": 86 }, { "x": 54, "y": 92 }, { "x": 56, "y": 96 }, { "x": 58, "y": 99 }, { "x": 59, "y": 101 }, { "x": 59, "y": 102 }, { "x": 60, "y": 102 }, { "x": 60, "y": 102 }, { "x": 60, "y": 101 }, { "x": 60, "y": 98 }, { "x": 61, "y": 90 }, { "x": 64, "y": 80 }, { "x": 65, "y": 73 }, { "x": 67, "y": 66 }, { "x": 69, "y": 60 }, { "x": 71, "y": 52 }, { "x": 72, "y": 49 }, { "x": 72, "y": 46 }, { "x": 73, "y": 44 }, { "x": 74, "y": 42 }, { "x": 74, "y": 41 }, { "x": 74, "y": 40 }, { "x": 74, "y": 40 }, { "x": 74, "y": 39 }, { "x": 74, "y": 39 }, { "x": 74, "y": 39 }, { "x": 74, "y": 39 }, { "x": 74, "y": 39 }, { "x": 74, "y": 39 }, { "x": 72, "y": 40 }, { "x": 67, "y": 43 }, { "x": 63, "y": 45 }, { "x": 60, "y": 47 }, { "x": 58, "y": 49 }, { "x": 56, "y": 50 }, { "x": 54, "y": 52 }, { "x": 52, "y": 52 }, { "x": 51, "y": 53 }, { "x": 50, "y": 54 }, { "x": 50, "y": 54 }, { "x": 50, "y": 54 }, { "x": 49, "y": 54 }, { "x": 49, "y": 54 }, { "x": 49, "y": 54 }, { "x": 49, "y": 54 }, { "x": 49, "y": 55 }, { "x": 49, "y": 55 }, { "x": 49, "y": 55 }, { "x": 48, "y": 55 }, { "x": 48, "y": 55 }, { "x": 48, "y": 55 }, { "x": 47, "y": 56 }, { "x": 46, "y": 56 }, { "x": 46, "y": 56 }, { "x": 46, "y": 56 }, { "x": 46, "y": 56 } ]'
```

to

```sql
\set pen '〰'
```

(where `〰` should be replaced with the JSON value copied just earlier) and run it:

```bash
psql -f code/handwriting.sql
```

If everything went well, you have just found out which character you've drawn! (Ideally, it matches your intent...)


## License

See `LICENSE`, with the following caveats:

* Mike Bostock' D3.js, located at `code/assets/d3.v4.min.js`, is licensed under the [BSD 3-Clause License](https://github.com/d3/d3/blob/master/LICENSE).
* The Iosevka font, to be found at `code/assets/iosevka-regular.*`, is licensed under the [SIL Open Font License Version 1.1](https://github.com/be5invis/Iosevka/blob/master/LICENSE.md).
* Most of the visualizations in `paper/`, `presentation/`, as well as `code/assets/guide.png` are based on Jack Schaedler's excellent interactive essay ["Back to the Future of
Handwriting Recognition"](https://jackschaedler.github.io/handwriting-recognition/), which is licensed under the [MIT License](https://github.com/jackschaedler/handwriting-recognition/blob/master/LICENSE).
* The videos `presentation/alankay*.mp4` of Alan Kay demoing GRAIL are taken from a talk entitled "Doing with Images Makes Symbols". As the're still under copyright protection, I'm technically engaging in [freebooting](https://www.urbandictionary.com/define.php?term=Freebooting) by including them in this repository. However, since the talk has been [available on archive.org since 2002](https://archive.org/details/AlanKeyD1987), I'm hopeful that nobody will mind too much.
* Similar caveats hold for `paper/grailconsole.png`, `presentation/approach.png`, `presentation/decisiontree.png`, the mockup used for `presentation/nexus5.jpg`, `presentation/pglogo.png`, and `presentation/tablet.jpg`.
