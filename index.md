---
layout: default
title: Home
permalink: /
---

<div class="hero">
  <img src="{{ '/static/logo_transparent.png' | relative_url }}" alt="AMSI Raccoon Lab" class="hero-logo">
  <h1>AMSI Raccoon Lab</h1>
  <p class="subtitle">The World's Most Intentionally Terrible Antivirus Scanner &mdash; an educational platform for understanding antimalware detection and evasion techniques.</p>
  <div class="stats">
    <div class="stat">
      <div class="stat-number">43</div>
      <div class="stat-label">Challenges</div>
    </div>
    <div class="stat">
      <div class="stat-number">6</div>
      <div class="stat-label">Categories</div>
    </div>
    <div class="stat">
      <div class="stat-number">43</div>
      <div class="stat-label">Solutions</div>
    </div>
  </div>
</div>

## Challenge Categories

<div class="card-grid">
  <a href="{{ '/challenges/#signature-detection-bypass' | relative_url }}" class="card">
    <div class="card-title">Signature Detection Bypass</div>
    <div class="card-description">Evade static string matching by transforming, encoding, or fragmenting known malware signatures.</div>
    <div class="card-meta">
      <span class="badge badge-category">14 Challenges</span>
      <span class="badge badge-easy">Easy - Hard</span>
    </div>
  </a>

  <a href="{{ '/challenges/#non-printable-ratio-bypass' | relative_url }}" class="card">
    <div class="card-title">Non-Printable Ratio Bypass</div>
    <div class="card-description">Defeat the scanner's non-printable byte analysis through encoding, padding, and size manipulation.</div>
    <div class="card-meta">
      <span class="badge badge-category">5 Challenges</span>
      <span class="badge badge-easy">Easy - Medium</span>
    </div>
  </a>

  <a href="{{ '/challenges/#small-executable-bypass' | relative_url }}" class="card">
    <div class="card-title">Small Executable Bypass</div>
    <div class="card-description">Circumvent the small executable heuristic that flags tiny files with suspicious extensions.</div>
    <div class="card-meta">
      <span class="badge badge-category">2 Challenges</span>
      <span class="badge badge-easy">Easy</span>
    </div>
  </a>

  <a href="{{ '/challenges/#extension-heuristic-bypass' | relative_url }}" class="card">
    <div class="card-title">Extension Heuristic Bypass</div>
    <div class="card-description">Exploit weaknesses in extension-based file type detection using Unicode tricks, ADS, and polyglots.</div>
    <div class="card-meta">
      <span class="badge badge-category">9 Challenges</span>
      <span class="badge badge-medium">Easy - Hard</span>
    </div>
  </a>

  <a href="{{ '/challenges/#amsi-bypass' | relative_url }}" class="card">
    <div class="card-title">AMSI Bypass</div>
    <div class="card-description">Disable or circumvent the Windows Antimalware Scan Interface through memory patching, hijacking, and more.</div>
    <div class="card-meta">
      <span class="badge badge-category">13 Challenges</span>
      <span class="badge badge-hard">Medium - Hard</span>
    </div>
  </a>

  <a href="{{ '/getting-started' | relative_url }}" class="card">
    <div class="card-title">Getting Started</div>
    <div class="card-description">New here? Learn how the scanner works, set up your environment, and tackle your first challenge.</div>
    <div class="card-meta">
      <span class="badge badge-category">Guide</span>
    </div>
  </a>
</div>

---

## How It Works

The AMSI Raccoon Lab scanner implements **6 detection checks** with intentional weaknesses:

| Check | Method | Action | Exploitable? |
|-------|--------|--------|:---:|
| 1 | Signature Scan (7 known strings) | **BLOCKS** | Yes |
| 2 | Extension Heuristic (11 extensions) | Warning only | Yes |
| 3 | Non-Printable Ratio (>40%, files >= 64B) | **BLOCKS** | Yes |
| 4 | Small Executable (<32B + suspicious ext) | **BLOCKS** | Yes |
| 5 | Suspicious Pattern (IEX, WebClient...) | Warning only | Yes |
| 6 | Entropy Check (>7.2 bits/byte, >= 128B) | Warning only | Yes |

> **Note:** This is NOT production security software. It is an educational tool designed for understanding antimalware evasion techniques in a safe, controlled environment.

---

## Quick Start

```powershell
# Clone the repository
git clone https://github.com/yourusername/MostShittyAV.git

# Build the scanner
nimble build

# Scan a file
.\nim_antimalware_sim.exe scan <file>

# Try your first challenge!
# Edit a script to bypass signature detection
```

Browse the [Challenges]({{ '/challenges/' | relative_url }}) to begin, or check the [Architecture]({{ '/architecture' | relative_url }}) page to understand the scanner internals.
