Lightroom StackSync plugin
==========================

## What it does

It adds a new **Copy flags across stacks** command in *Library -> Plug-in
Extras*.

Once clicked, it takes each of the *currently selected* photos, looks at its
flag status (rejected, picked or unflagged), and copies this flag status to all
other photos in the stack which this photo is in.

## Why would I want that?

* Flags are usually used for filtering photos. Selecting which of them to keep,
  and which of them to remove permanently.

* Stacks are often used for grouping HDR and Panorama sources.

* When you filter photos with flags, usually you will flag only the top photo
  in each of your stacks. The rest of the photos in the stack will not get
  automatically flagged during this process.

* HDR, photomerge and deghosting algorithms might improve in the future. If you
  want to keep (or reject) a top photo in your stack, then it's often
  a good idea to keep (or reject) all photos in this stack.

* StackSync allows you to do exactly that.

## Installation

1. Download the ZIP file (look for the *Clone or download* button on
   [this page](https://github.com/wrygiel/stacksync.lrplugin)).

2. Extract it. Once you do this, you should have a `stacksync.lrplugin` folder
   somewhere on your drive.

3. Install it in Lightroom [in the regular fashion]
   (https://www.google.com/search?q=installing+lightroom+plugins).
