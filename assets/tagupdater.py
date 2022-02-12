#!/usr/bin/python3
import glob
import os

post_dir = '_posts/'
tag_dir = 'tag/'

if not os.path.exists(tag_dir):
    os.makedirs(tag_dir)

filenames = glob.glob(post_dir + '*md')

total_tags = []
for filename in filenames:
    f = open(filename, 'r', encoding='utf8')
    preamble_entered = False
    for line in f:
        if not preamble_entered:
            if line.strip() == "---":
                preamble_found = True
                preamble_entered = True
                continue
        if preamble_entered:
            tokens = line.strip().split()
            if tokens[0] == "tags:":
                total_tags.extend(tokens[1:])
                break
            elif tokens[0] == "---":
                break
    f.close()
total_tags = set(total_tags)
print("Total tags found:", total_tags)

print("Removing old tag pages:")
old_tags = glob.glob(tag_dir + '*.md')
for tag in old_tags:
    os.remove(tag)
    print("\tremoved:", tag)

print("Creating new tag pages:")
for tag in total_tags:
    tag_filename = tag_dir + tag + '.md'
    f = open(tag_filename, 'a')
    write_str = '---\nlayout: tagpage\n' \
        + 'title: \"Tag: '  + tag + '\"\n' \
        + 'tag: ' + tag + '\n' \
        + 'robots: noindex\n' \
        + '---\n'
    f.write(write_str)
    f.close()
    print("\tcreated:", tag_filename)
