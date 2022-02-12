---
layout: page
title: About
permalink: /about/
---
{%- assign date_format = site.minima.date_format | default: "%b %-d, %Y" -%}	

<br>
{% include heading.html
my_heading="Current position"
%}
**Postdoc Researcher** - University of Bergamo, department of Engineering
<br>
Topic: Information technology for the protection of data
<br>
[my resume](https://drive.google.com/file/d/1cQji7DeukMcoQFjRU8TMIkE1x-ehXNge/view?usp=sharing)


{% include heading.html
my_heading="Education"
%}
Software Engineering - University of Bergamo
<br>
**PhD program in Engineering and Applied Sciences**
<br>
{{ "2018-09-01" | date: date_format }} - {{ "2021-09-31" | date: date_format }}
<br>
Expected graduation date: _May 2022_
<br>
Advisor: _prof. Stefano Paraboschi_
<br>
Thesis: _Technologies for the secure collection, sanitization, processing and release of data_

Software Engineering - University of Bergamo
<br>
**Master of Science (MSc)**
<br>
{{ "2016-09-01" | date: date_format }} - {{ "2018-07-17" | date: date_format }}
<br>
`GPA: 4.0/4.0` - Graduated summa cum laude
<br>
Thesis: _Transforming query trees for cost optimization in secure multi-provider execution_


Software Engineering - University of Bergamo
<br>
**Bachelor of Science (BSc)**
<br>
{{ "2013-09-01" | date: date_format }} - {{ "2016-07-19" | date: date_format }}

{% include heading.html
my_heading="Skills"
%}

**Core competencies**:

* Programming languages: `Go`, `Python`

* Software: `Ubuntu`, `Emacs`, `git`, `Make`

* Scientific writing with `LaTeX`

* Access control techniques

**Other** programming languages/frameworks/tools used occasionaly
(say, less than 3 projects):

* Programming Languages: `Rust`, `C++`, `Java`, `Javascript`, `SQL`,
  `C`, `Elisp`, `M4`, `TE`, `CIL`, `ODRL`, `RDF`
  
* Software: `Docker`, `Postgres`, `Redis`, `Deno`, `Bazel`, `Apache 
  Spark`, `FRESCO mpc`, `Z3`, `FUSE`, `eBPF`
  
* see [my dotfiles](https://github.com/dariofad/dot-emacs)

**Languages**:
* Italian (native), English (fluent)

{% include heading.html
my_heading="Awards"
%}
University of Bergamo Alumni Association
<br>
Dept. of Management, Information and Production Engineering
<br>
**LUBERG - New graduate of the year**
<br>
{{ "2019-11-19" | date: date_format }}
<br>
<a href='http://www.luberg.it/eccellenze/proclamazione-neolaureati-dellanno-premio-agli-studi-2/'>LUBERG new graduate</a> of the year award rewards talent, determination and commitment of graduates who stand out for a particularly brilliant academic record, the results achieved in the degree course, the originality and the scientific rigor of the thesis.

{% include heading.html
my_heading="Work Experience"
%}
`Autonomous collaborations`
* **Partner**: UniBg
  <br>
  Development of a prototype for the management of a language for security policies in a Digital Data Market
  - {{ "2021-05-03" | date: date_format }} - {{ "2021-09-13" | date: date_format }}
  - {{ "2020-07-20" | date: date_format }} - {{ "2020-11-20" | date: date_format }}
  - {{ "2019-07-04" | date: date_format }} - {{ "2019-11-04" | date: date_format }}

`Teaching experience`

Teaching assistant, courses at University of Bergamo

* 
**Introduction to programming in Python**
<br>
Year `2018`, `2020`
<br>
Topics: Basic types, control-flow statements, functions, lists

* 
**Data Bases I**
<br>
Year `2019`, `2020`, `2021`
<br>
Topics: Structured Query Language, Conceptual and Logical database modeling

* 
**Data Bases II**
<br>
Year: `2019`, `2020`, `2021`
<br>
Topics: Concurrency, scheduling, distributed databases, XQUERY

* 
**Computer Security**
<br>
Year: `2021`
<br>
Topics: Access Control, DAC, MAC, Capabilities (Linux), Isolation of 3rd-party apps in Android

{% include heading.html
my_heading="Other experiences"
%}
`Competitions`

* **Cybersecurity Games & Conference** (CSAW 2021) - Applied Research Competition, Top 10 Finalist in Europe ([certificate](https://drive.google.com/file/d/1kUxstkCdRUDYZQDfT2TFn8_X568Y-3R5/view?usp=sharing))
* **Google hash code 2019 Finals** - Team: Unibg Seclab, [38th place](https://codingcompetitions.withgoogle.com/hashcode/archive/2019)

`Thesis projects`

* **Supervised 30+ thesis students** - [Topics](https://seclab.unibg.it/tesi/)

`Programming`

* **AlgoExpert** - Completed 100 problems in Python ([certificate](https://drive.google.com/file/d/107ZkuFqHwE4L3oNnyURqF-whdiYl39r-/view?usp=sharing))


{% include heading.html
my_heading="Software Contributions"
%}

* 
**SEApp: Bringing Mandatory Access Control to Android Apps**  <a href='https://github.com/matthewrossi/seapp'>[link]</a>
<br>
A modification to AOSP to extend the mandatory access control layer to Android apps. SEApp leverages SELinux to restrict access to the internal storage, restrict access to services, and isolate vulnerability prone components. This is achieved executing components on dedicated processes. A dedicated app policy module (written in CIL) regulates the permissions associated to each process. Changes to AOSP are implemented in both Java and C++.

* 
**ITYT:  Practical Time-Locked Secrets using Smart Contracts** <a href='https://github.com/unibg-seclab/ityt'>[link]</a>
<br>
A framework to deploy time-locks using the blockchain. It leverages multi-party computation to split a secret among many parties, each obtaining a share. The parties need to cooperate to recover the secret following a pre-defined protocol. The protocol is programmed using a smart contract. The smart contract is developed in Solidity, while the multi-party computation protocol is developed in Java using the FRESCO programming framework.

* 
**Spark-based Mondrian** <a href='https://github.com/mosaicrown/mondrian'>[link]</a>
<br>
A Dockerized Apache Spark-based version of Mondrian, a sanitization algorithm to achieve <i>k-anonimity</i>. It is executed on a Spark cluster with a varying number of executors. Docker containers are used to scale the number of executors. The anonymization app is an Apache Spark application implemented in Python.

* 
**dot-emacs** <a href='https://github.com/dariofad/dot-emacs'>[link]</a>
<br>
A minimal version of my <tt>.emacs.d/</tt> useful to anyone that may want to test Emacs for code development. Mostly Elisp code.

* 
**MOSAICrOWN Policy Engine** <a href='https://github.com/mosaicrown/policy-engine'>[link]</a>
<br>
The policy engine is the tool responsible for parsing the MOSAICrOWN policy and checking whether a subject request is permitted or denied. Policies are written in ODRL, while the tool is implemented in Python.
