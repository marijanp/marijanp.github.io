<h1 id="title">1000 instances of flake-utils</h1>
<p>
  <address>By <a rel="author">Marijan</a></address> on <time id="post-date" datetime="2025-05-26">2025-05-26</time>
</p>

<p id="excerpt">
Learn about an alternative to flake-utils for creating Nix Flake outputs. Use nixpkgs.lib.genAttrs to support multiple systems and avoid dependency bloat.
</p>

<link rel="canonical" href="https://nixcademy.com/posts/1000-instances-of-flake-utils/" />

> **Note:** Originally published on [nixcademy.com](https://nixcademy.com/posts/1000-instances-of-flake-utils/)

When writing a Nix Flake, one tedious yet important task is to expose your packages and other outputs for different platforms. You want to declare them not just for the platforms you're officially supporting and testing on, but ideally for many more. Let's take a look at an example:

```nix
# flake.nix
...
outputs = { self, ... }: {
  packages.x86_64-linux = {
    packageA = ...;
    packageB = ...;
    packageC = ...;
  };
  packages.aarch64-linux = {
    packageA = ...;
    packageB = ...;
    packageC = ...;
  };
  packages.x86_64-darwin = {
    packageA = ...;
    packageB = ...;
    packageC = ...;
  };
  ...
  devShells.x86_64-linux.default = ...;
  devShells.aarch64-linux.default = ...;
  devShells.x86_64-darwin.default = ...;
  ...
}
```

This repetition is annoying, but declaring as many systems as possible is important because Flakes don't support a way to externally override the system parameter when invoking the Nix command. If a consumer of this Flake is on a `i686-linux` machine, for example, and tries to run `packageA`, they'll get an error:

```console
$ nix run .#packageA
error: flake 'git+file:///...' does not provide attribute 'apps.i686-linux.packageA', 'packages.i686-linux.packageA', 'legacyPackages.i686-linux.packageA' or 'packageA'
```

Even if we didn't intend for users on `i686-linux` to use our package, and we haven't built or tested for that platform, it's good practice to empower any user to attempt to consume the package if they want to on whatever system they run. While exposing packages via an [overlay](https://nixcademy.com/posts/mastering-nixpkgs-overlays-techniques-and-best-practice/) is also an option, it's an additional step for them. (We recommend doing that in any case, though it's a separate topic and it requires users to instantiate `nixpkgs` configured with their system and that overlay).

Unfortunately, there is also no command-line option that allows a user to override the Flake author's declared systems. You might think `--system` would do the trick, but it merely looks for an output matching that system:

```console
$ nix run .#packageA --system i686-linux
error: flake 'git+file:///...' does not provide attribute 'packages.i686-linux.packageA', 'legacyPackages.i686-linux.packageA' or 'packageA'
       Did you mean packages?
```

Therefore, as a Flake author, you'd ideally want to declare all platforms you've built and tested for, and many more , moreover you would like to achieve that without excessive repetition.

## The Allure of *flake-utils*

Many people in the Nix community facing this issue of repetition have decided to introduce *[flake-utils](https://github.com/numtide/flake-utils)* as a dependency to solve this issue. It provides helper functions, notably `eachSystem` and `eachDefaultSystem`, to create outputs for different systems without being repetitive. `eachDefaultSystem` is simply `eachSystem` partially applied with a predefined `defaultSystems` list:

```nix
eachDefaultSystem = eachSystem defaultSystems
```

In this post, we'll highlight some issues with introducing *flake-utils* as an evaluation dependency and argue that you often don't need it, as you can easily craft your own `eachSystem`-like function with a single line of code.

## The Obscurity Problem with *flake-utils*

Let's start by taking a look at how `eachDefaultSystem` solves the repetition problem:

```nix
# flake.nix
{
	inputs.flake-utils.url = "github:numtide/flake-utils";
	outputs = { self, flake-utils }:
	flake-utils.eachDefaultSystem (system: {
		packages = {
			packageA = ...;
			packageB = ...;
			packageC = ...;
		};
		devShells.default = ...;
	});
}
```

You call `eachDefaultSystem` with a callback that produces your outputs attribute set for a given system. *flake-utils* then invokes this callback for each of its "default" systems.

This solves the repetition, which is nice. But an observation: What exactly is a "default system"? Is `x86_64-linux` one? How about `i686-linux`? As a reader of this code, I have two ways to find out: consult the *flake-utils* documentation or run `nix flake show` to see the produced outputs.

What was obvious in the earlier, more verbose code now introduces a bit of cognitive overhead. The author is implicitly requiring prior knowledge or extra steps from users or future maintainers to understand what's happening. What if the *flake-utils* maintainers decide `riscv64` is now a "default system", or `aarch64-linux` is not  a "default system" anymore? Discovering this change isn't hard - check the documentation or run `nix flake show` - but it's an extra step and it's not obvious from reading the code.

According to [A Philosophy of Software Design](https://web.stanford.edu/~ouster/cgi-bin/book.php) by John Ousterhout, two causes of complexity are *dependencies* and *obscurity*. Dependencies are often intentionally introduced to manage complexity and improve maintainability and are almost inevitable. Since they can paradoxically be a cause of complexity we want to introduce them wisely. Obscurity occurs when important information is not apparent, e.g. when a too generic variable forces you to consult the documentation. A clean design tends to minimize the amount of required documentation.

With *flake-utils*, we've introduced a dependency, and `eachDefaultSystem` is arguably obscure regarding its "default" systems.

Code is typically written once by a few people but read many times by many people with varying levels of expertise. I'd argue we can do better, even when using *flake-utils*. Instead of `eachDefaultSystem`, let's use `eachSystem` to eliminate the obscurity:

```nix
# flake.nix
{
	inputs.flake-utils.url = "github:numtide/flake-utils";
	outputs = { self, flake-utils }:
	let
		supportedSystems = [ "x86_64-linux" "aarch64-linux" "i686-linux" ];
	in
	flake-utils.eachSystem supportedSystems (system: {
		packages = {
			packageA = ...;
			packageB = ...;
			packageC = ...;
		};
		devShells.default = ...;
	});
}
```

This is clearer, but the dependency on *flake-utils* remains. While seemingly small, this dependency can lead to bloat in real-world scenarios.

## The Dependency Problem with flake-utils

The *flake-utils* [README](https://github.com/numtide/flake-utils/blob/main/README.md) highlights a nice property: it doesn't depend on *nixpkgs*. So, if your Flake's outputs don't need *nixpkgs*, you could depend only on *flake-utils*, which is much smaller than *nixpkgs* (which, as of early 2025, is around 43 MiB big). In the other case, if you do depend on *nixpkgs*, you don't have to explicitly override *flake-utils*'s *nixpkgs* input, because it doesn't have one. That is, you avoid needing to write:

```nix
# flake.nix
inputs = {
  nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  flake-utils.url = "github:numtide/flake-utils"
  # We don't have to do this:
  flake-utils.input.nixpkgs.follows = "nixpkgs";
};
```

However, projects often grow to depend on many Flakes, not just *nixpkgs* and *flake-utils*. We've observed many projects using *flake-utils* solely for this per-system output generation. Often, authors are unaware that another Flake they depend on also uses f*lake-utils*, and they forget to make their dependencies follow a single *flake-utils* instance. I.e. they forget to do that override for *flake-utils*:

```nix
# flake.nix
inputs = {
  flake-utils.url = "github:numtide/flake-utils"
  flake-a.url = ...;
  flake-a.inputs.flake-utils.follows = "flake-utils";
};
```

If these follows directives are missing, your `flake.lock` file can end up with multiple pins for *flake-utils*. Consequently, when you build a package that relies on these other Flakes, you might have download the *flake-utils* checkout multiple times in order to evaluate your Flake. This issue is widespread: [a Sourcegraph query](https://sourcegraph.com/search?q=context:global+flake-utils_+file:flake.lock&patternType=keyword&sm=0) for `flake.lock` files mentioning `flake-utils_*` yields over 4100 results.

Moreover [another Sourcegraph query](https://sourcegraph.com/search?q=context:global+flake-utils.url+and+nixpkgs.url+file:flake.nix&patternType=keyword&sm=0) shows over 4200 `flake.nix` files mentioning both `flake-utils.url` and `nixpkgs.url`, implying that the property of not depending on *nixpkgs* is often irrelevant, as most projects do depend it anyway.

So, the observation is: while *flake-utils* itself doesn't depend on *nixpkgs*, many projects use both. Furthermore, projects often depend on other Flakes that also use *flake-utils*, and their authors might not consistently override evaluation inputs, leading to bloat.

Let's leverage this fact and break this cycle: The *nixpkgs* library offers `genAttrs`, a function that can achieve a similar outcome to `eachSystem`.

## The Alternative

The *flake-utils* [documentation](https://github.com/numtide/flake-utils?tab=readme-ov-file#eachsystem--system---system---attrs) mentions a type signature for `eachSystem`:

```text
eachSystem :: [<system>] -> (<system> -> attrs)
```
We can look up the type signature for `genAttrs` in the Nix repl:
```console
nix-repl>:doc lib.genAttrs
...
Type

      | genAttrs :: [ String ] -> (String -> Any) -> AttrSet

Examples

    :::{.example}

## lib.attrsets.genAttrs usage example

      | genAttrs [ "foo" "bar" ] (name: "x_" + name)
      | => { foo = "x_foo"; bar = "x_bar"; }

    :::
```

It looks quite similar, actually identical. The *flake-utils* documentation just omits the return type of the function. So If we pass a list of system strings to `genAttrs` and have the callback produce an attribute set, we get this:

```console
nix-repl>:p lib.genAttrs [ "x86_64-linux" "aarch64-linux" ] (system: { packageA = "..."; })
{
  aarch64-linux = { hello = "..."; };
  x86_64-linux = { hello = "..."; };
}
```

This output structure is quite close to what the Flake schema expects. Let's rewrite our Flake using `genAttrs`:

```nix
# flake.nix
{
	inputs.nixpkgs.url = "github:NixOS/nixpkgs";
	outputs = { self, nixpkgs }:
	let
		supportedSystems = [ "x86_64-linux" "aarch64-linux" "i686-linux" ];
		eachSupportedSystem = nixpkgs.lib.genAttrs supportedSystems;
	in
	{
		packages = eachSupportedSystem (system: {
			packageA = ...;
			packageB = ...;
			packageC = ...;
		});
		devShells = eachSupportedSystem (system: {
			default = ...;
		});
	};
}
```

We've eliminated a dependency with a simple helper! We still have some repetition because `genAttrs` itself doesn't restructure nested attributes (like `flake-utils`' `eachSystem` can), meaning we call `eachSupportedSystem` for `packages` and then again for `devShells`. This seems like a slight drawback, but this is a small price to pay to get rid of a dependency which itself is just used for a single functionality.

It's also worth mentioning that the *nixpkgs* library exposes a list of common systems relevant to Flakes, which you can use with `genAttrs` or your custom helpers: `lib.systems.flakeExposed`. That arguably introduces a bit of obscurity, but sometimes we have to or want to be pragmatic.

```nix
nix-repl> lib.systems.flakeExposed
[
  "x86_64-linux"
  "aarch64-linux"
  "x86_64-darwin"
  "armv6l-linux"
  "armv7l-linux"
  "i686-linux"
  "aarch64-darwin"
  "powerpc64le-linux"
  "riscv64-linux"
  "x86_64-freebsd"
]
```

With these two library members you can replicate `eachDefaultSystem` if you depend on *nixpkgs* by defining:

```nix
eachSupportedSystem = lib.genAttrs lib.systems.flakeExposed
```

without introducing another dependency.

## Conclusion

Defining Flake outputs supporting multiple systems is an important and tedious task, since users can't easily override the system. While *flake-utils* helps reduce repetition, it can also introduce obscurity and dependency issues, as we've seen.

`nixpkgs.lib.genAttrs` offers a more direct, built-in alternative. Using it with an explicit list of systems gives you clear control without an extra dependency. You avoid increasing the amount of evaluation dependencies for yourself and users, achieving the same goal of reducing repetition in your Flake outputs just as with `flake-utils`.

But this is just the beginning. By handling the per-system generation ourselves with `lib.genAttrs`, we can now build more powerful, custom behaviors directly into our Flake logic. Stay tuned for a follow-up where we'll explain how to extend this foundation to conveniently manage per-system `pkgs` instances and other advanced configurations - going beyond what simple per-system helpers typically offer.
