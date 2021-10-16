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
**Researcher** - Università degli Studi di Bergamo
<br>
Topic: Information technology for data protection
<br>
{% include heading.html
my_heading="Education"
%}
Software Engineering - Università degli Studi di Bergamo
<br>
**PhD program in Engineering and Applied Sciences**
<br>
{{ "2019-09-01" | date: date_format }} - {{ "2021-09-31" | date: date_format }}

Software Engineering - Università degli Studi di Bergamo
<br>
**Master of Science (MSc)**
<br>
{{ "2016-09-01" | date: date_format }} - {{ "2018-07-17" | date: date_format }}
<br>
`GPA: 4.0/4.0` - Graduated summa cum laude

Software Engineering - Università degli Studi di Bergamo
<br>
**Bachelor of Science (BSc)**
<br>
{{ "2013-09-01" | date: date_format }} - {{ "2016-07-19" | date: date_format }}

{% include heading.html
my_heading="Awards"
%}
Univerity of Bergamo Alumni Association
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
* 
**Partner**: UniBg
<br>
Extension of a prototype for the management of a language for security policies in a Digital Data Market
<br>
{{ "2021-05-03" | date: date_format }} - {{ "2021-09-13" | date: date_format }}

* 
**Partner**: UniBg
<br>
Development of a prototype for the management of a security policy language in a Digital Data Market
<br>
{{ "2020-07-20" | date: date_format }} - {{ "2020-11-20" | date: date_format }}

* 
**Partner**: UniBg
<br>
 Development of a prototype for the management of data in a Digital Data Market
<br>
{{ "2019-07-04" | date: date_format }} - {{ "2019-11-04" | date: date_format }}

`Teaching experience`

Teaching assistant, courses at Università degli Studi di Bergamo

* 
**Introduction to programming in Python**
<br>
Years `2018`, `2020`
<br>
Topics: Basic types, control-flow statements, functions, lists

* 
**Data Bases I**
<br>
Years `2019`, `2020`, `2021`
<br>
Topics: Structured Query Language, Conceptual and Logical database modeling

* 
**Data Bases II**
<br>
Years: `2019`, `2020`, `2021`
<br>
Topics: Concurrency, scheduling, distributed databases, XQUERY

* 
**Computer Security**
<br>
Years: `2021`
<br>
Topics: Access Control, DAC, MAC, Capabilities (Linux), Isolation of 3rd-party apps in Android

{% include heading.html
my_heading="Other experiences"
%}
`Programming`

* 
**AlgoExpert** - Completed 100 problems in Python ([certificate](https://drive.google.com/file/d/107ZkuFqHwE4L3oNnyURqF-whdiYl39r-/view?usp=sharing))

`Coding competitions`
* 
**Google hash code 2019 Finals** - Team: Unibg Seclab, [38th place](https://codingcompetitions.withgoogle.com/hashcode/archive/2019)

`Thesis projects`

* 
**Supervised 30+ thesis students** - [Topics](https://seclab.unibg.it/tesi/)

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
A minimal version of my <tt>.emacs</tt> files useful to anybody that wants to test Emacs with EXWM as its main driver. To use it, you only have to install Emacs, <tt>use-package</tt> and <tt>xorg</tt>. The repo collects mostly Elisp code. Upgrades planned.

* 
**MOSAICrOWN Policy Engine** <a href='https://github.com/mosaicrown/policy-engine'>[link]</a>
<br>
The policy engine is the tool responsible for parsing the MOSAICrOWN policy and checking whether a subject request is permitted or denied. Policies are written in ODRL, while the tool is implemented in Python. Upcoming releases scheduled for 2021.

{% include heading.html
my_heading="Skills"
%}

Software/Programming Languages that I use regularly:
* `Ubuntu`, `Emacs`, `git`, `Python`, `LaTeX`, `Make`

Policy/Programming Languages and tools that I've used occasionally:
* `M4`, `TE`, `CIL`, `Go`, `Java`, `C`, `C++`, `SPARQL`, `Bazel`, `Docker`

Personal interest areas (software related):
* Understanding how Linux (or any other derived OS) works, applied cryptography

Languages:
* Italian (native), English

{% include heading.html
my_heading="Interests"
%}
Traveling, reading Manga (when I'm not messing up with my Linux distro ( ⚆ _ ⚆ ) ), technology

[my resume](https://drive.google.com/file/d/1cQji7DeukMcoQFjRU8TMIkE1x-ehXNge/view?usp=sharing)
