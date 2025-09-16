const vscode = require("vscode");
const { exec } = require("child_process");
const fs = require("fs");
const path = require("path");

/**
 * Macro configuration settings
 * { [name: string]: {              ... Name of the macro
 *    no: number,                   ... Order of the macro
 *    func: ()=> string | undefined ... Name of the body of the macro function
 *  }
 * }
 */
module.exports.macroCommands = {
  FormatMarkdown: {
    no: 1,
    func: formatMarkdown,
  },
  DeleteRemoteBranches: {
    no: 2,
    func: deleteRemoteBranches,
  },
  DeleteLocalBranches: {
    no: 3,
    func: deleteLocalBranches,
  },
  ReplaceToBladeFromHtml: {
    no: 4,
    func: replaceToBladeFromHtml,
  },
  ReplaceToLaravelCss: {
    no: 5,
    func: replaceToLaravelCss,
  },
  ConvertDirListToMarkdown: {
    no: 6,
    func: convertDirListToMarkdown,
  },
  EmbedLinkedFileContents: {
    no: 7,
    func: embedLinkedFileContents,
  },
};

/**
 * Markdown を整形
 */
function formatMarkdown() {
  const editor = vscode.window.activeTextEditor;
  if (!editor) {
    return "Editor is not opening.";
  }

  const document = editor.document;
  const fullRange = new vscode.Range(document.positionAt(0), document.positionAt(document.getText().length));
  const text = document.getText();
  if (text.length > 0) {
    let replaced = text.replace(/  +\|/g, " |");
    replaced = replaced.replace(/\|  +/g, "| ");
    replaced = replaced.replace(/----+/g, "---");
    replaced = replaced.replace(/(#+ )\*\*([^\*]+)\*\*/g, "$1$2");
    replaced = replaced.replace(/(#+ )\d+\. (.+)/g, "$1$2");
    replaced = replaced.replace(/\| なし \|/g, "| |");
    replaced = replaced.replace(/(.+) --> ([^：]+)：(.+)/g, "$1 --> $2: $3");
    replaced = replaced.replace(/\[＊\] --> /g, "[*] --> ");
    editor.edit((editBuilder) => {
      editBuilder.replace(fullRange, replaced);
    });
  }
}

/**
 * Delete remote branches (excluding develop, main, and master).
 */
function deleteRemoteBranches() {
  const workspaceFolders = vscode.workspace.workspaceFolders;
  if (!workspaceFolders || workspaceFolders.length === 0) {
    vscode.window.showErrorMessage("No workspace folder open.");
    return;
  }
  const cwd = workspaceFolders[0].uri.fsPath;
  const command = "git branch -r | grep -vE 'origin/(develop|main|master)' | sed 's/origin\\///' | xargs -I {} git push origin --delete {}";
  exec(command, { cwd }, (error, stdout, stderr) => {
    if (error) {
      vscode.window.showErrorMessage("Error: " + error.message);
      return;
    }
    if (stderr) {
      vscode.window.showWarningMessage("Stderr: " + stderr);
    }
    vscode.window.showInformationMessage("Remote branches deletion completed.");
  });
}

/**
 * Delete local branches (excluding develop, main, and master).
 */
function deleteLocalBranches() {
  const workspaceFolders = vscode.workspace.workspaceFolders;
  if (!workspaceFolders || workspaceFolders.length === 0) {
    vscode.window.showErrorMessage("No workspace folder open.");
    return;
  }
  const cwd = workspaceFolders[0].uri.fsPath;
  const command = "git branch | grep -vE '(develop|main|master)' | xargs git branch -D";
  exec(command, { cwd }, (error, stdout, stderr) => {
    if (error) {
      vscode.window.showErrorMessage("Error: " + error.message);
      return;
    }
    if (stderr) {
      vscode.window.showWarningMessage("Stderr: " + stderr);
    }
    vscode.window.showInformationMessage("Local branches deletion completed.");
  });
}

function replaceToBladeFromHtml() {
  const editor = vscode.window.activeTextEditor;
  if (!editor) {
    return "Editor is not opening.";
  }

  const document = editor.document;
  const fullRange = new vscode.Range(document.positionAt(0), document.positionAt(document.getText().length));
  const text = document.getText();
  if (text.length > 0) {
    let replaced = text.replace(/src="\.\.\/([^"]+)"/g, `src="{{ asset('$1') }}"`);
    // fix: chain the second replace to 'replaced', not 'text'
    replaced = replaced.replace(/href="\.\.\/([^"]+)"/g, `href="{{ asset('$1') }}"`);
    editor.edit((editBuilder) => {
      editBuilder.replace(fullRange, replaced);
    });
  }
}

function replaceToLaravelCss() {
  const editor = vscode.window.activeTextEditor;
  if (!editor) {
    return "Editor is not opening.";
  }

  const document = editor.document;
  const fullRange = new vscode.Range(document.positionAt(0), document.positionAt(document.getText().length));
  const text = document.getText();
  if (text.length > 0) {
    let replaced = text.replace(/src\: url\("\.\.(.*)"\)/g, `src: asset("$1")`);
    editor.edit((editBuilder) => {
      editBuilder.replace(fullRange, replaced);
    });
  }
}

/**
 * FooMacro
 */
function fooFunc() {
  const editor = vscode.window.activeTextEditor;
  if (!editor) {
    return "Editor is not opening.";
  }

  const document = editor.document;
  const selection = editor.selection;
  const text = document.getText(selection);
  if (text.length > 0) {
    editor.edit((editBuilder) => {
      // To surround a selected text in double quotes(Multi selection is not supported).
      editBuilder.replace(selection, `"${text}"`);
    });
  }
}

/**
 * BarMacro(asynchronous)
 */
async function barFunc() {
  const editor = vscode.window.activeTextEditor;
  if (!editor) {
    return "Editor is not opening.";
  }

  await vscode.window.showInformationMessage("Hello VSCode Macros!");
  // Returns nothing when successful.
}

/**
 * 選択範囲またはドキュメント全体の 'ls -R' 出力を
 * Markdown のネストリスト形式に変換するマクロ
 */
function convertDirListToMarkdown() {
  const rawText = getSelectedOrAllText();
  const isWindows = /^PS\s+/m.test(rawText);
  const result = isWindows ? convertWindowsOutput(rawText) : convertUnixOutput(rawText);
  replaceEditorContent(rawText, result);
}

/**
 * Handle PowerShell 'ls -R' output using Windows-specific logic
 * Adapted from working single-block implementation
 */
function convertWindowsOutput(text) {
  const lines = text.split(/\r?\n/);
  const sep = "\\";
  const outputBlocks = [];
  let currentBlock = null;
  let baseDir = "";
  let indent = 0;

  function pushBlock() {
    if (currentBlock) {
      outputBlocks.push(currentBlock.join("\n"));
      currentBlock = null;
    }
  }

  for (const line of lines) {
    // Detect 'ls -R' header
    const cmdMatch = line.match(/^PS\s+(.+?)>\s*ls\s+-R\s+(.+?)\s*$/);
    if (cmdMatch) {
      // finish previous
      pushBlock();
      const workspacePath = cmdMatch[1] || (vscode.workspace.workspaceFolders ? [0].uri.fsPath : "");
      let targetPath = cmdMatch[2] || ".";
      targetPath = targetPath.replace(/^\.\\/, "").replace(/\\+$/, "");
      baseDir = workspacePath + sep + targetPath;
      const displayRoot = `${targetPath}${sep}`;
      currentBlock = [];
      currentBlock.push(`* ${displayRoot.replaceAll("\\", "/")}`);
      indent = 0;
      continue;
    }
    if (!currentBlock) continue;
    // Directory entries
    const dirMatch = line.match(/ディレクトリ: (.+)$/);
    if (dirMatch) {
      const full = dirMatch[1].replace(/\\+$/, "");
      if (full !== baseDir) {
        let rel = full.startsWith(baseDir + sep) ? full.slice(baseDir.length + 1) : full;
        rel = rel.replace(/\\+$/, "");
        if (rel && rel !== ".") {
          const parts = rel.split(sep);
          indent = parts.length;
          currentBlock.push(`${"  ".repeat(indent)}* ${parts.join("/")}/`);
        }
      }
      continue;
    }
    // File entries
    const fileMatch = line.match(/-a----\s+\d+\/\d+\/\d+\s+\d+:\d+\s+\d+\s+(.+)$/);
    if (fileMatch) {
      currentBlock.push(`${"  ".repeat(indent + 1)}* ${fileMatch[1]}`);
    }
  }
  // finalize
  pushBlock();
  return outputBlocks.join("\n\n");
}

/**
 * Handle Unix 'ls -R' output
 */
function convertUnixOutput(text) {
  const lines = text.split(/\r?\n/);
  const sep = "/";
  const blocks = [];
  let current = null;
  let baseDir = "";
  let indent = 0;

  function finish() {
    if (current) {
      blocks.push(current.join("\n"));
      current = null;
    }
  }

  for (const raw of lines) {
    const line = raw.trimEnd();
    // Detect new block: header 'ls -al -R <path>'
    const hdr = line.match(/^ls\b.*-R\s+(.+)$/);
    if (hdr) {
      finish();
      current = [];
      let target = hdr[1].replace(/^\.\//, "").replace(/\/+$|\\+$/g, "");
      baseDir = target;
      indent = 0;
      current.push(`* ${target}${sep}`);
      continue;
    }
    if (!current) continue;
    // Skip total lines
    if (/^total\s+\d+/.test(line)) continue;
    // Skip '.' and '..' entries
    if (/^drwx.*\s+\.$/.test(line) || /^drwx.*\s+\.\.$/.test(line)) continue;
    // Subdirectory header 'path/to/dir:'
    const sub = line.match(/^(.+?):$/);
    if (sub) {
      const full = sub[1].replace(/\/+$|\\+$/g, "");
      let rel = full.startsWith(baseDir + "/") ? full.slice(baseDir.length + 1) : full;
      rel = rel.replace(/\/+$|\\+$/g, "");
      if (rel && rel !== ".") {
        const parts = rel.split("/");
        indent = parts.length;
        current.push(`${"  ".repeat(indent)}* ${rel}${sep}`);
      }
      continue;
    }
    // File entry: last token with extension
    const fm = line.match(/\s+(\S+\.\w+)$/);
    if (fm) {
      current.push(`${"  ".repeat(indent + 1)}* ${fm[1]}`);
    }
  }
  finish();
  return blocks.join("\n\n");
}

/** Utility: get selection or whole document */
function getSelectedOrAllText() {
  const editor = vscode.window.activeTextEditor;
  const doc = editor.document;
  const sel = editor.selection;
  return sel.isEmpty ? doc.getText() : doc.getText(sel);
}

/** Utility: replace content in editor */
function replaceEditorContent(original, result) {
  const editor = vscode.window.activeTextEditor;
  const doc = editor.document;
  const sel = editor.selection;
  const range = sel.isEmpty ? new vscode.Range(doc.positionAt(0), doc.positionAt(original.length)) : sel;
  editor.edit((e) => e.replace(range, result));
}

/**
 * Markdown 見出し直後のコードフェンス内を、リンク先ファイルの内容で上書きする
 * - マッチ条件を緩和
 *   - 見出し: ^#{1,6} のいずれか
 *   - 見出し行末の追記許可（リンクの後ろに文字があっても可）
 *   - 見出し直後の空行は 0 行以上
 *   - フェンス: ``` または ~~~、本数は 3 本以上なら可（閉じは同じ記号で3本以上なら可）
 * - “対象なし/読めない” はエラーではなく警告表示
 */
function embedLinkedFileContents() {
  const editor = vscode.window.activeTextEditor;
  if (!editor) return "Editor is not opening.";
  const document = editor.document;

  // Markdownのみ対象（情報表示 → 警告に変更してもよいなら下行を showWarningMessage に）
  if (document.languageId && document.languageId !== "markdown") {
    vscode.window.showInformationMessage("This macro targets Markdown documents only.");
    return;
  }

  const original = document.getText();
  if (!original) return;

  const docDir = path.dirname(document.uri.fsPath);
  const eol = document.eol === vscode.EndOfLine.CRLF ? "\r\n" : "\n";

  /**
   * キャプチャ:
   *  1: 見出し〜空行（複数可）を含むブロック
   *  2: リンクURL部（最短一致）
   *  3: コードフェンスのインデント
   *  4: 開きフェンス全文（例: ``` / ~~~~~）
   *  5: フェンス記号（` or ~）
   *  6: 言語/情報文字列（先頭の空白は除去して保持）
   *  7: 既存ブロック中身
   *
   * 閉じフェンス: 行頭の空白任意 + (5と同じ記号){3,}
   */
  const pattern = new RegExp(
    // 見出し行: `## [name](path)` を含む。末尾に追記あってもOK。直後の空行は 0〜n 行。
    String.raw`(^#{1,6}\s+\[[^\]]+\]\((.*?)\)[^\r\n]*\r?\n(?:[ \t]*\r?\n)*)` +
      // 開きフェンス行: インデント + ``` or ~~~（3本以上）。言語は任意。
      String.raw`([ \t]*)(([\x60~])\5{2,})[ \t]*([^\r\n]*)\r?\n` +
      // 本文（最短一致） + 閉じフェンス（同じ記号、3本以上）
      String.raw`([\s\S]*?)^[ \t]*\5{3,}[ \t]*(?=\r?\n|$)`,
    "gm"
  );

  const warnings = [];
  let hit = 0,
    replacedAny = false;

  const replaced = original.replace(pattern, (match, headerWithLinkBlock, rawPath, indent, openFence, fenceChar, lang, _body) => {
    hit++;

    let filePath = (rawPath || "").trim();

    // <path> 形式を許容
    if (filePath.startsWith("<") && filePath.endsWith(">")) {
      filePath = filePath.slice(1, -1);
    }
    // "(url \"title\")" のようなタイトル併記は URL 部だけに
    filePath = filePath.split(/\s+/)[0];

    const resolved = path.isAbsolute(filePath) ? filePath : path.normalize(path.join(docDir, filePath));

    let fileContent;
    try {
      fileContent = fs.readFileSync(resolved, "utf8");
    } catch (e) {
      warnings.push(`Cannot read file: ${resolved}`);
      return match; // 読めない場合は変更しない
    }

    // BOM 除去
    if (fileContent.charCodeAt(0) === 0xfeff) fileContent = fileContent.slice(1);

    // 改行を編集中ドキュメントの EOL に統一
    fileContent = fileContent.replace(/\r\n|\r|\n/g, eol);
    if (!fileContent.endsWith(eol)) fileContent += eol;

    replacedAny = true;
    const langOut = lang ? lang.trim() : "";
    // フェンスは開きの文字列(openFence)をそのまま再利用（本数/記号を保持）
    return `${headerWithLinkBlock}${indent}${openFence}${langOut}${eol}${fileContent}${indent}${openFence}`;
  });

  if (replacedAny) {
    const fullRange = new vscode.Range(document.positionAt(0), document.positionAt(original.length));
    editor.edit((eb) => eb.replace(fullRange, replaced));
  }

  // 表示仕様：エラーではなく警告
  if (!hit) {
    vscode.window.showWarningMessage("置換対象の '## [name](path)' + コードフェンス（``` または ~~~）が見つかりませんでした。");
  } else if (warnings.length) {
    vscode.window.showWarningMessage(`更新: ${replacedAny ? "あり" : "なし"} / 警告: ${warnings.length}件 - ${warnings.join(" / ")}`);
  } else {
    vscode.window.showInformationMessage(`更新: ${replacedAny ? "あり" : "なし"} / 警告: 0件`);
  }
}
