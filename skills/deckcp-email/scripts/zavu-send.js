#!/usr/bin/env node
/**
 * zavu-send.js — send a transactional email via the Zavu messaging API.
 * Zero model tokens. Node 18+ (global fetch). Reads ZAVU_API_KEY from the
 * environment or a local .env.local / .env (so it works in the deckcp repo
 * without exporting anything).
 *
 * Usage:
 *   node zavu-send.js --to her@example.com --subject "..." --text "..." \
 *     [--cc me@example.com] [--cc other@x.com] [--reply-to me@example.com] \
 *     [--text-file body.txt] [--sender <zavu-sender-id>] [--send]
 *
 * SAFETY: dry-run is the DEFAULT. Nothing is sent unless you pass --send.
 * Dry-run prints the exact payload (API key redacted) so you can eyeball the
 * recipient, cc, and body before anything leaves the building.
 *
 * Exit codes: 0 ok / dry-run, 1 bad args, 2 missing key, 3 send failure.
 */
"use strict";
const fs = require("fs");
const path = require("path");

const ZAVU_MESSAGES_URL = "https://api.zavu.dev/v1/messages";

function loadDotenv() {
  // Shallow-merge .env.local then .env into process.env WITHOUT overriding
  // anything already exported. Enough for KEY=value lines; not a full parser.
  for (const file of [".env.local", ".env"]) {
    let raw;
    try {
      raw = fs.readFileSync(path.resolve(process.cwd(), file), "utf8");
    } catch {
      continue;
    }
    for (const line of raw.split("\n")) {
      const m = line.match(/^\s*([A-Z0-9_]+)\s*=\s*(.*)\s*$/);
      if (!m) continue;
      const key = m[1];
      if (process.env[key] !== undefined) continue;
      let val = m[2];
      if (
        (val.startsWith('"') && val.endsWith('"')) ||
        (val.startsWith("'") && val.endsWith("'"))
      ) {
        val = val.slice(1, -1);
      }
      process.env[key] = val;
    }
  }
}

function parseArgs(argv) {
  const out = { cc: [], send: false };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    const next = () => argv[++i];
    switch (a) {
      case "--to": out.to = next(); break;
      case "--cc": out.cc.push(next()); break;
      case "--subject": out.subject = next(); break;
      case "--text": out.text = next(); break;
      case "--text-file": out.textFile = next(); break;
      case "--reply-to": out.replyTo = next(); break;
      case "--sender": out.sender = next(); break;
      case "--send": out.send = true; break;
      case "--dry-run": out.send = false; break;
      default:
        console.error("unknown arg: " + a);
        process.exit(1);
    }
  }
  return out;
}

function fail(code, msg) {
  console.error(msg);
  process.exit(code);
}

async function main() {
  loadDotenv();
  const args = parseArgs(process.argv.slice(2));

  if (args.textFile && !args.text) {
    try {
      args.text = fs.readFileSync(path.resolve(process.cwd(), args.textFile), "utf8");
    } catch (e) {
      fail(1, "could not read --text-file: " + e.message);
    }
  }

  if (!args.to) fail(1, "--to is required");
  if (!args.subject) fail(1, "--subject is required");
  if (!args.text) fail(1, "--text or --text-file is required");

  const apiKey = process.env.ZAVU_API_KEY;
  if (!apiKey) fail(2, "ZAVU_API_KEY not set (env or .env.local)");
  const sender = args.sender || process.env.ZAVU_SENDER;

  const payload = {
    to: args.to,
    channel: "email",
    subject: args.subject,
    text: args.text,
    ...(args.cc.length ? { cc: args.cc } : {}),
    ...(args.replyTo ? { replyTo: args.replyTo } : {}),
  };

  if (!args.send) {
    console.log("DRY RUN — not sending. Pass --send to actually send.\n");
    console.log("POST " + ZAVU_MESSAGES_URL);
    console.log("Authorization: Bearer <ZAVU_API_KEY redacted>");
    if (sender) console.log("Zavu-Sender: " + sender);
    console.log(JSON.stringify(payload, null, 2));
    return;
  }

  const res = await fetch(ZAVU_MESSAGES_URL, {
    method: "POST",
    headers: {
      Authorization: "Bearer " + apiKey,
      "Content-Type": "application/json",
      ...(sender ? { "Zavu-Sender": sender } : {}),
    },
    body: JSON.stringify(payload),
  });

  const bodyText = await res.text();
  if (!res.ok) {
    fail(3, "send failed: " + res.status + " " + bodyText.slice(0, 400));
  }
  console.log("sent ok (" + res.status + ")");
  console.log(bodyText.slice(0, 400));
}

main().catch((e) => fail(3, e && e.message ? e.message : String(e)));
