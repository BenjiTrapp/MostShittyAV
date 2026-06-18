---
title: "Challenge 18: Encrypted Payload"
challenge_number: 18
difficulty: medium
category: "Non-Printable Ratio Bypass"
permalink: /challenges/18-encrypted-payload/
---

# Challenge 18: Encrypted Payload

**Difficulty:** Medium  
**Category:** Non-Printable Ratio Bypass

---

## Objective

Use encryption to completely transform a malicious payload into something the scanner cannot signature-match. Navigate both the entropy check and the non-printable byte ratio check to avoid all flags.

## Scanner Behavior

The scanner performs **two relevant checks** on file contents:

1. **Non-Printable Byte Ratio:** If more than 40% of bytes (in files >= 64 bytes) are non-printable, the file is flagged as suspicious.

2. **Shannon Entropy Check:** The scanner calculates the Shannon entropy of the file's byte distribution. If entropy exceeds **7.2 bits/byte**, it issues a warning. However, this check **only warns — it does not block** the file.

The scanner does not attempt decryption. It has no knowledge of keys, algorithms, or encrypted data structures. It only sees raw bytes.

## Rules

- Start with a payload that contains known malicious signatures (words from the signature list).
- Encrypt the payload so that no signatures are detectable in the file on disk.
- The final file must not be blocked by the non-printable ratio check.
- The entropy warning is acceptable (it doesn't block), but eliminating it is a bonus.
- Include a decryption mechanism or document how the payload would be recovered.

## Hints

1. AES (and most encryption) produces output that looks random — high entropy, uniformly distributed bytes.
2. High entropy triggers the warning (>7.2 bits/byte), but the warning doesn't block. The real problem is the non-printable ratio.
3. Encrypted output is essentially random bytes — most of them will be non-printable. That **will** trigger the 40% ratio check... unless you do something about the representation.
4. What if you took the ciphertext and re-encoded it into something entirely printable before writing it to disk?

---

[View Solution](../solutions/18-encrypted-payload.md)
