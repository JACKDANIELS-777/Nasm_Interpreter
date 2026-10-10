# Nasm Interpreter (Dia_64)

An expression interpreter written from scratch in **x64 NASM assembly** for Windows: about **1,400 lines** (950 of
them instructions, not counting blank lines and comments), with no C code and no libraries beyond four Windows API calls.
Written in Notepad and built from cmd.

It has a lexer, a recursive parser that builds a real **abstract syntax tree** in a hand-managed memory arena, and a
tree-walking evaluator that computes the result with the CPU's own integer instructions.

<img width="1816" height="953" alt="image" src="https://github.com/user-attachments/assets/cd6b8d1c-d8d9-49b2-b433-c4de071c0721" />

```
a=99;a+1;          ->  100
2*3+4*5;           ->  26
10-3-2;            ->  5      (left to right, like real maths)
1*9-18/9;1*9-27/9; ->  6      (several statements, last one wins)
```

## The pipeline

### 1. Lexer: tokens are AST nodes from the start

The lexer reads the input once, character by character, and writes every token straight into `ast_arena` as a
32-byte node:

| Offset | Field | Meaning |
|---|---|---|
| +0 | type | `100` integer, `25` name, `2` `+`/`-`, `8` `*`/`/`, `1` `=`, `15` `;`, `5` end |
| +8 | value | the number, the variable's character, or which operator |
| +16 | left | pointer to the left child |
| +24 | right | pointer to the right child |

So there's no separate token list. The parser doesn't copy anything: it wires up the `left` and `right` pointers
of nodes that already exist, turning the flat token stream into a tree in place.

Dispatch avoids branch chains: each character check is a `cmp` plus a `cmove` that picks a jump target, then one
`jmp r8`.

### 2. Parser: precedence on the machine stack

`Parser` walks the nodes and calls itself for the right-hand side of every operator, passing the current
precedence level. Left operands wait on the CPU stack (`push`) until their operator `pop`s them and links them in.
`*` and `/` bind tighter than `+` and `-`, so `1*9-18/9` becomes:

```
          [ - ]
         /     \
     [ * ]     [ / ]
    /     \   /     \
  [1]    [9] [18]   [9]
```

### 3. Evaluator: recursive tree walk

`WalkTree` evaluates the tree depth first and returns the value in `rax`:

- `*` uses `imul`; `/` uses `cqo` + `idiv` (signed 128-by-64 division).
- The tree leans right, so `10-3-2` is stored as `10-(3...2)`. To still get left-to-right results, the walker
  passes a flag down the right side and **flips the sign of the next `+`/`-`**, which gives `5`, not `9`.
- `a=99` stores 99 in a slot of the `mem` table, picked by the variable's character code (`'a'` = 97, times 8
  bytes). Reading `a` later loads it from the same slot.

Every `;` ends a statement. The roots are kept in a `statements` table and run in order. The last result becomes
the process exit code.

## Build and run

Needs NASM and MinGW-w64 (`gcc` is only used as the linker). `build.bat`:

```bat
nasm -f win64 program.asm -o program.obj
gcc program.obj -o program.exe -nostdlib -lkernel32 -s -Wl,--subsystem,console -Wl,-N
program.exe
```

`-nostdlib` leaves out the C runtime completely: the program talks to Windows through `kernel32` and nothing
else, and `main`'s return value becomes the process exit code.

Type a program, for example `a=99;a+1;`, and press Enter. It prints a trace of the lexer, parser and evaluator,
showing each node as `NT:` (type) and `NV:` (value). Then check the result:

```cmd
echo %errorlevel%
100
```

## Verified examples

Each of these was built from `V0.03` with the `build.bat` flags above and run (the program text baked in rather
than typed); the number is the exit code.

| Program | Result |
|---|---|
| `1*9-18/9;` | 7 |
| `1*9-18/9;1*9-27/9;` | 6 |
| `2+3*4;` | 14 |
| `2*3+4*5;` | 26 |
| `10-3-2;` | 5 |
| `10-3+2;` | 9 |
| `8/2/2;` | 2 |
| `100/7;` | 14 |
| `12345+1;` | 12346 |
| `a=99;a+1;` | 100 |
| `a=2;b=a+1;b;` | 3 |
| `a=1+2*3;a;` | 7 |

## Limitations

- Whole numbers only; no negative literals and no brackets for grouping yet.
- Variables are one character long.
- A variable on the right side of an operator (`3*a`, `a*b`, `x*x`) isn't handled yet. On the left it works:
  `a*3`, `b=a+1`.
- A statement that is only a number (`9;`) doesn't return that number.
- Input is read from a real console (`ReadConsoleA`), up to 100 characters, so it can't be piped in.
- `print(...)` is recognised by the lexer but is still a work in progress.

## Versions

| Folder | What changed |
|---|---|
| `Versions/Code/V0.01` | First version: lexer, parser, evaluator |
| `Versions/Code/V0.02` | All four operators with precedence, plus a worked example (`Example.txt`) |
| `Versions/Code/V0.03` | A statement that is only a variable name (`a;`) |

---



### Data scraping and AI usage policy

> AI data scraping and model training are prohibited. No part of this repository, including the assembly source,
> architecture notes or documentation, may be used to train, fine-tune or benchmark machine learning models or
> generative AI systems.
