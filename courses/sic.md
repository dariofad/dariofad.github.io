---
title: 
permalink: /sic.html
layout: default
---

## Computer security - Teaching material

Feel free to send me an email to <dario.facchinetti@unibg.it>, but **please use your student email account** to send the message (and attach only PDF files). 

### Topic: Access Control and Sandboxing in OS

In these talks we're going to discuss some of the standard Access Control methods used to restrict access and strengthen sandboxing in modern Operating Systems. The goal is to understand the pros and cons of Discretionary Access Control (`DAC`), Mandatory Access Control (`MAC`) and Capability-based Access Control.

The talks can also be considered a practical introduction to `Unix-style permissions`, `SELinux` and `Linux capabilities`. You'll learn how to use it and configure it. Also, the slides collect many examples taken from real policies (especially from Linux and Android).

In the third talk we'll discuss how Android isolates applications from each other and from the system. We'll also introduce you to our research product [SEApp](https://www.usenix.org/conference/usenixsecurity21/presentation/rossi) (a modification to the Android Open Source Project to extend MAC to apps).

### Introduction to Sandboxing, DAC and MAC

* [Slides](https://drive.google.com/file/d/1Hnr0sr7g5MFYxIpbNsIQFD6d_LlbhKoE/view?usp=sharing)
* Program
  * Introduction to Access control techniques, DAC and MAC
  * Unix-style permissions (managing users and groups, set-UID-root, sticky bit)
  * LSM and `SELinux` (`kernel policy language`, MLS, `m4` macros, command line tools)

### Linux Capabilities

* [Slides](https://drive.google.com/file/d/1DEqifdSUuEOMwvHaPX7wEX_O29BCrabf/view?usp=sharing)
* Program
  * Introduction to Linux Capabilities
  * Thread capabilities vs File capabilities
  * Capability sets
  * What happens during an `execve`
  * Set-user-ID-root programs with capabilities
  * Textual representation, set, get, and decode
  * Capability-aware vs Capability-dumb programs
  
### Isolation of apps in Android

* [Slides](https://drive.google.com/file/d/1n2bZToTnnbnlJffqRWkTeoFmXG82nI8R/view?usp=sharing)
* Program
  * Application Sandboxing in Android: DAC and MAC
    * SEAndroid Context Files
    * Android Permissions and introduction to the Binder IPC
  * SEApp: Bringing Mandatory Access Control to Android Apps
    * Motivation and Idea
	* Policy language and Policy Module Constraints
	* Install time and Runtime support
	* Demo using a Pixel 2 XL / Pixel 3

### Schedule

* Talk 1: 04/05/2021
* Talk 2: 11/05/2021
* Talk 3: 18/05/2021 - Matthew Rossi
