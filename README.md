
# <img src="https://github.com/joh-ga/RubyCrumbler/blob/13828a0252549dff68a03cd30bcacc94fa5a6496/Pipeline/icons/rubycrumbler-logo.png" height=75 />

Ready to crumble your text for common NLP tasks? This repository is home of RubyCrumbler, a simple script to download, that provides a GUI desktop application written in Ruby to apply common Natural Language Processing (NLP) tasks on your text files.

Hier jenachdem dann noch einfügen das entweder als Skript oder als release datei heruntergeladen werden kann.<br>
Sprachen; Englisch und dann evtl Deutsch<br>

## Requirements
wenn User skript nutzt statt release dann<br>
* Ruby Version 3.02
* Gems in the Gemfile (müssen wir noch erstellen am Ende)

## GUI
Hier vorschau vom main window der finalen GUI (Screenshot in Mac, Windows, Linux) einfügen

## Description of Features
***Pre-Processing***<br>
**Data Cleaning:** This includes removing redundant whitespaces, punctuation (redundant dots), special symbols (e.g., line break, new line), hash tags, HTML tags, and URLs.<br>
**Normalization:** This includes removing punctuation symbols (dot, colon, comma, semicolon, exclamation and question mark).<br>
**Normalization (lowercase):** This includes removing punctuation symbols (dot, colon, comma, semicolon, exclamation and question mark) as well as converting the text into lowercase.<br>
**Normalization (contractions):** This includes removing punctuation symbols (dot, colon, comma, semicolon, exclamation and question mark) as well as converting contractions (abbreviation for a sequence of words like “don’t”) into their original form (e.g., do not).<br>

***Natural Language Processing – Tasks***<br>
**Tokenization:** This includes splitting the pre-processed data into individual characters or tokens.<br>
**Stopword Removal:** Stopwords are words that do not carry much meaning but are important grammatically as, for example, “to” or “but”. This feature includes the removal of stopwords.<br>
**Stemming:** This includes the reduction of a word to its stem (a character sequence shared by related words) by clipping inflectional and partially derivational suffixes. A word’s stem therefore does not necessarily have to be a semantically meaningful word. Word stems and lemmatized base forms may overlap. Examples: computing - compute, sung - sung, obviously - obvious.<br>
**Lemmatization:** This includes reduction of a word to its semantic base form according to POS classification. Lemmatized base forms and word stems may overlap. Examples: computing - compute, sung - sing, obviously - obviously.<br>
**Part-of-Speech Tagging (POS):** This includes identifying and labeling the parts of speech of text data.<br>
**Named Entity Recognition (NER):** This includes labeling the so-called named entities in the data such as persons, organizations, and places.<br>

## File Naming Convention
To enable a quick identification and location of your converted document depending on the feature applied, the following file naming convention is used.<br>
Abbreviations are added to the source file name to indicate the features that have been applied to the document. The suffix of the new file name indicates the ouput file for the corresponding feature. For example, the file named “myfirsttext_cl_nlc_tok.txt” is the output file of the tokenization step.<br><br>
**Overview of the feature abbreviations:**
* Data cleaning = cl
* Normalization = n
* Normalization (lowercase) = l
* Normalization (contractions) = c
* Tokenization = tok
* Stopword Removal = stpw
* Stemming = stem
* Lemmatization = lem
* Part-of-Speech Tagging = pos
* Named Entity Recognition = ner

For each feature step the output format is TXT. POS tagging and NER are also saved in CSV and XML output format.

## Pipeline Structure of RubyCrumbler
The program is built based on the following pipeline structure.<br>
![alt text](https://github.com/joh-ga/RubyCrumbler/blob/ca6c0fb394cb192a6b1c4a035a6f308d1610b2d4/Pipeline/icons/rubycrumbler-pipeline.png)<br>

