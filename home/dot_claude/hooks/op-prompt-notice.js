#!/usr/bin/env node
// PreToolUse hook (Bash|PowerShell): when a command is about to trigger a
// 1Password approval prompt, show a one-line reason in Claude Code and as a
// Windows toast (also from WSL). Never blocks: any error just exits 0.
"use strict";
const { execFileSync, spawn } = require("child_process");
const { readFileSync } = require("fs");

function isWsl() {
  if (process.platform !== "linux") return false;
  if (process.env.WSL_DISTRO_NAME) return true;
  try { return /microsoft/i.test(readFileSync("/proc/version", "utf8")); } catch { return false; }
}

function gitConfig(cwd, key) {
  try {
    return execFileSync("git", ["config", "--get", key], { cwd, encoding: "utf8", timeout: 2000, stdio: ["ignore", "pipe", "ignore"] }).trim();
  } catch { return ""; }
}

const isSshUrl = (u) => /^(ssh:\/\/|[\w.-]+@[\w.-]+:)/.test(u);

// Returns what 1Password is being asked for, or null if no prompt expected.
function detect(cmd, cwd) {
  const sep = String.raw`(?:^|[\s;&|(\x60]|\$\()`;
  if (new RegExp(sep + String.raw`op(?:\.exe)?\s+(?!--?(?:version|help)\b)\w`).test(cmd)) return "secret read via op CLI";
  if (new RegExp(sep + String.raw`(?:ssh|scp|sftp)(?:\.exe)?\s`).test(cmd) || /ssh_(?:exec|multi)\.py|scp_transfer\.py/.test(cmd)) return "SSH key for remote login";
  if (new RegExp(sep + String.raw`chezmoi\s+(?:apply|update|git\b)`).test(cmd)) return "commit signing / SSH push of dotfiles";

  const reasons = [];
  const git = new RegExp(sep + String.raw`git\s+(?:-C\s+\S+\s+)?(?:-c\s+\S+\s+)*([\w-]+)([^;&|]*)`, "g");
  for (const m of cmd.matchAll(git)) {
    const [, sub, rest] = m;
    if (/^(commit|merge|rebase|cherry-pick|revert|am|commit-tree)$/.test(sub) || (sub === "tag" && /\s-[a-z]*s/.test(rest))) {
      if (gitConfig(cwd, "commit.gpgsign") === "true" && !/--no-gpg-sign/.test(rest)) reasons.push("SSH key to sign the commit");
    } else if (/^(push|pull|fetch|clone|ls-remote|remote|submodule)$/.test(sub)) {
      const urlArg = rest.match(/(ssh:\/\/\S+|[\w.-]+@[\w.-]+:\S+|https?:\/\/\S+)/);
      const remote = (rest.trim().split(/\s+/).find((a) => a && !a.startsWith("-")) || "origin");
      const url = urlArg ? urlArg[1] : gitConfig(cwd, `remote.${remote}.url`) || gitConfig(cwd, "remote.origin.url");
      if (isSshUrl(url)) reasons.push(`SSH key for git ${sub}`);
    }
  }
  return reasons.length ? [...new Set(reasons)].join(" + ") : null;
}

function toast(line) {
  if (process.platform !== "win32" && !isWsl()) return;
  const esc = (s) => s.replace(/'/g, "''").slice(0, 250);
  const script = `
    $null = [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime]
    $xml = [Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent([Windows.UI.Notifications.ToastTemplateType]::ToastText02)
    $t = $xml.GetElementsByTagName('text')
    $null = $t.Item(0).AppendChild($xml.CreateTextNode('Claude Code - 1Password request'))
    $null = $t.Item(1).AppendChild($xml.CreateTextNode('${esc(line)}'))
    $app = '{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\\WindowsPowerShell\\v1.0\\powershell.exe'
    [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($app).Show([Windows.UI.Notifications.ToastNotification]::new($xml))`;
  const child = spawn("powershell.exe", ["-NoProfile", "-NonInteractive", "-Command", script], { detached: true, stdio: "ignore", windowsHide: true });
  child.on("error", () => {});
  child.unref();
}

try {
  const input = JSON.parse(readFileSync(0, "utf8"));
  const ti = input.tool_input || {};
  const cmd = String(ti.command || "");
  const what = detect(cmd, input.cwd || process.cwd());
  if (what) {
    const purpose = (ti.description || cmd).replace(/\s+/g, " ").trim().slice(0, 120);
    const line = `${what} — ${purpose}`;
    if (process.env.OP_NOTICE_DRYRUN !== "1") toast(line);
    process.stdout.write(JSON.stringify({ systemMessage: `🔐 1Password prompt: ${line}` }));
  }
} catch { /* never interfere with the tool call */ }
process.exit(0);
