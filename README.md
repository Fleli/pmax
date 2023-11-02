# PMaxCompiler

Welcome to the PMax repository. PMax is a programming language that draws inspiration from C. It is built specifically with Hackerspace NTNU's [breadboard computer](https://github.com/hackerspace-ntnu/BreadboardComputer) in mind. While it might not match the sheer elegance of C or the power of Swift, PMax aims to provide an easy-to-use platform to make breadboard computer programming accessible. 

Within this repository, you will find the PMax compiler. The compiler translates PMax source code into breadboard computer assembly code. Although it is functional, the language and compiler still has a long way to go in terms of performance and usability. Several optimizations passes will be added later on to improve performance of the generated code. In addition, new language features that make the code more readable and "user-friendly" are on their way.

## Repository Structure

All code is found within `Sources/PMaxCompiler`. 

The folder `__main` provides the `Compiler` class, which represents the external interface for this repository. The `_Compiler` folder contains several definitions and functions that help the compilation, for example `FileOption`, a profiler and a pass manager.

The four folders `0Frontend`, `1PIL`, `2TAC`, and `3ASM` are also found within `Sources/PMaxCompiler`. These contain the actual code for source-to-assembly transformation. For further documentation on each of these passes, please refer to the `_Docs` folder. Once finished, the `.md` files there will provide an in-depth view into each step.

Finally, the `_Extensions` folder is used to extend existing types. An `SLRNode` extension is placed there in order to preserve it when SwiftParse and SwiftLex overwrites the frontend files.

## Coming Features

Some important and useful features are not implemented yet, but are on their way:
1. **Calling functions outside of expressions**. Right now, the grammar only allows for calling functions on the right-hand side of a declaration or an assignment, or in expression evaluations in `if`s, `while`s and so on. The option to simply call a function as the whole statement, like `function(a, b, c);`, is very important. This has high priority and will be implemented shortly.
2. **Instance methods**. A nice feature that all modern languages have, is the ability to define _instance methods_, functions defined within a type defintion (class, struct, enum etc.) that can use an instance of that type, usually called `self` or `this`, and operate on it. See the [discussion](https://github.com/Fleli/PMax-StdLib) on the standard library page for more about this.
3. **Imports**. A crucial feature in a programming language is the ability to import other files and link them together. This has very high priority.
4. **Enumerations**. It is often desirable to use a very restricted set of possible values. Enumerations (`enum`s) have good support in most languages and solve this problem well. Swift's `enum` model with the option to use associated and raw values is very nice, and considerably more useful than Java's and C's models. It is preferable to implement something similar to that of Swift's model, but it does not have extremely high priority.
5. **Custom operators**. Adding support for custom operators (`+`, `-`, `<<`, etc.) on derived types (structs) would significantly improve the ergonomics of the language. For example, being able to add two `Point`s together with the `+` operator (`p1 + p2`) is signifantly clearer and less verbose that `add_points(p1, p2)`. This is especially useful since PMax does not allow function overloading. Another useful operator is subscripting, `[...]`, which could be defined on arbitrary types as specified by the user.  

## Language

The PMax programming language shares a lot of syntax and semantics with C. Some key similarities include:
- The `int` type being built in to the language
- Allowing the user to define _structs_ that group data together
- The widespread use of pointers for dynamic memory management
- The language is statically typed, but its typing system is weak and obeys the programmer's type casts

A more elaborate description of the language is in the works.

## Compiler

The compiler is a large and complex system, so it is best explained section by section. However, a short summary is provided here.
- The compiler receives _source code_ written by the programmer. This is a `String`. It is turned into an array of `Token` instances by the _lexer_. Each `Token` represents a lexical "word", for instance `int`, `512` or `x` in the source code. It also contains a _type_ that is used to distinguish control symbols (e.g. `{`) from integer literals (`integer`).
- The array of tokens is _parsed_ by an SLR parser. This results in a tree that conveys the structure of the input. In other words, the linear `[Token]` is now converted into a _tree_ that explicitly expresses nesting. Each node in the tree is an `SLRNode` instance. An `SLRNode` can have an arbitrary number of child `SLRNode`s. It also has a `String` that describes its _type_ (for example `Assignment`, `Expression` or `Function`).
- The tree of `SLRNode` objects is converted into another tree of designated classes for each type. Now, the `Assignment` node from the parsing stage is stored in its own `Assignment` class, with fields `lhs: Expression` and `rhs: Expression` (`Expression` is an `enum` with cases for unary and binary expressions, pure variable references and so on). This is much easier to work with for later stages of the compiler that an unspecialized `SLRNode` tree.
- The tree of designated objects, for example `Assignment` and `While`, is then lowered to the _PMax Intermediate Language_, shortened to _PIL_. PIL type-checks all expressions and synthesizes types from subexpressions where inference is needed. It also generates memory layouts for struct types. In addition, PIL verifies the existence of variables where they are used. PIL emits an intermediate representation similar to what it received from the previous step, but (type) annotated, verified and some meta information.
- After receiving a well-typed and (probably) meaningful program from PIL, we wish to remove the tree structure so that the program becomes closer to the machine. The flat structure we wish to convert to is called _Three-Address Code_ (TAC), because it deals with at most three addresses (operands) per statement. The TAC lowerer walks the PIL tree in order to flatten it. It also submits errors for some semantic issues in the code, like assigning an unassignable expression (e.g. `a + b`). The TAC stage outputs a number of _labels_, each containing a linear list of TAC Statements.
- The last stage is lowering to (breadboard) assembly. Lowering to assembly code involves translating each TAC statement into its corresponding list of assembly instructions. There is a quite direct mapping between the two. The result from this stage is a `String` that can be assembled by an assembler to create a binary.

## Standard Library

The standard library is being implemented in its own [repository](https://github.com/Fleli/PMax-StdLib). It will contain frequently used algorithms and data structures. Before the standard library can be used, however, the compiler needs to support an `import` statement and some infrastructure to "talk" to code outside the current source file.

## Separation of Concerns

Today, the compiler is a very monolithic piece of software. This package, `PMaxCompiler`, translates the whole source file into its corresponding assembly code. Separating compilation from assembling is a good thing because it allows for a clear separation of concerns, improving clarity and compartmentalization. It is desirable to further divide the compiler into more standalone repositories because
(a) it introduces fewer bugs, since each module can be easily tested alone without considering the whole pipeline
(b) optimization passes can be more easily added if there is a clear protocol for communication between passes
(c) sifting out the syntactic frontend and generalizing the semantic checks will allow several languages to use the same code for semantic checks. Then, the compiler can be used not only by Hackerspace NTNU's breadboard computer project, but in other applications as well. 
(d) sifting out the backend allows for using an LLVM-like project to perform optimizations. Using a specialized library for optimizations is likely to result in better-performing code

The benefits of a library-based structure are clear. However, it will require much work to get such a model done right, which might present a challenge with the limited time of Hackerspace NTNU's breadboard computer project. Nevertheless, proper planning and external input on the needs of such libraries will make it doable.

Points (c) and (d) indicate the need for two major libraries:
- A semantic checker that performs type inference, type checking, scope resolution and more. This will replace today's PIL and (in part) TAC stages, and provide more functionality and better error messages, in addition to providing a standard interface so that more frontends can utilize it.
- An LLVM-like tool (significantly downscaled, of course) that serves as a code optimizer for many languages. Since no optimizations are present in today's PMax compiler, this won't replace any of the code in the `PMaxCompiler` package. This tool would use a generic instruction set that abstracts the physical machine and is easily optimizable.

In addition, some TAC- and all the ASM-related code would need to be replaced by a new tool that is
- compatible with the LLVM-like tool's IR
- specific to the breadboard computer's assembly language (like ASM is today)
