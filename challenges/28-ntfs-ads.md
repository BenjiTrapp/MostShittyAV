---
title: "Challenge 28: NTFS Alternate Data Streams"
challenge_number: 28
difficulty: hard
category: "Extension Heuristic Bypass"
permalink: /challenges/28-ntfs-ads/
---

# Challenge 28: NTFS Alternate Data Streams

**Difficulty:** Hard  
**Category:** Extension Heuristic Bypass

## Objective

NTFS supports Alternate Data Streams (ADS) - additional named data streams attached to any file. The scanner only reads and analyzes the main `$DATA` stream of a file. Your goal is to hide executable content in an alternate stream where the scanner will never look.

## Scanner Behavior

- The scanner opens files using standard file I/O, which accesses only the default (unnamed) `$DATA` stream.
- Extension checking is performed on the base filename only.
- The scanner does not enumerate or inspect alternate data streams.
- ADS content is completely invisible to the scanner's analysis pipeline.
- The scanner does not parse or recognize the colon (`:`) syntax used to address alternate streams.

## Hints

1. On NTFS, `file.txt:hidden` is a valid path that refers to a stream named `hidden` attached to `file.txt`.
2. You can write arbitrary data to an ADS: the content is stored on disk but invisible to normal directory listings.
3. Alternate streams can be executed directly by some Windows utilities and APIs.
4. Consider how `wscript`, `cscript`, `powershell`, or `cmd` handle ADS paths.
5. The base file can be completely innocuous (even empty) while the ADS contains the real payload.

---

[View Solution](../solutions/28-ntfs-ads.md)
