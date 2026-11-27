# Architecture, interop, rendering and testing

Sources: the official guide ([web apps](https://guide.elm-lang.org/webapps/),
[interop](https://guide.elm-lang.org/interop/)), Evan Czaplicki's talk "The
Life of a File", Richard Feldman's "Make Impossible States Impossible",
[Elm Patterns](https://sporto.github.io/elm-patterns/),
[elm-spa-example](https://github.com/rtfeldman/elm-spa-example) and the
`elm/html` source. Patterns shown in [examples/](../examples/) were compiled
and tested; the rest is *researched*.

## Choosing a program

| Program | Use when |
|---|---|
| `Browser.sandbox` | Toys and teaching: no commands, subscriptions or flags |
| `Browser.element` | Elm runs inside part of a page another system controls |
| `Browser.document` | Elm owns `<title>` and `<body>` |
| `Browser.application` | Elm also owns URL changes and routing |

`document` and `application` take over the whole body, so JavaScript must not
mutate it. With `application`, every `<a href>` click arrives as
`onUrlRequest`: answer `Browser.Internal url` with `Nav.pushUrl key
(Url.toString url)` and `Browser.External href` with `Nav.load href`, and
react to the URL only in `onUrlChange`, which also fires for back and
forward. Keep the `Nav.Key` from `init` in the model. Parse URLs into a
`Route` custom type in one `Route` module, with one function that turns a
route back into a URL, and never build paths by hand elsewhere. Links always
need a real `href`; an anchor with only `onClick` is not keyboard accessible.

`Url.Parser.string` returns a path segment still percent-encoded: an id
`a b/c` comes back as `a%20b%2Fc`. When segments can contain such characters,
parse them with `Url.Parser.custom "ID" Url.percentDecode` and build URLs with
`Url.Builder`, which encodes. Test the route round trip
(`Route.fromUrl (Route.toUrl r) == Just r`) with awkward ids; a skill trial
caught this bug only through that test.

## Modeling

- **Make impossible states impossible.** Prefer one custom type over several
  fields that must agree. Keep a selection inside the structure that holds
  the list (a zipper `{ before, current, after }`) rather than as an index
  next to it.
- **Opaque types** expose the type, not its constructor, and offer only
  validating constructors (`fromString : String -> Result Error Email`).
- **Phantom types** tag values with compile-time facts:
  `type Id kind = Id String` with `type UserTag = UserTag` keeps an
  `Id UserTag` out of a function that wants `Id PostTag`.
- **Non-empty lists** (`( a, List a )`) remove `Maybe` from `head` and
  `maximum` where emptiness is impossible.
- **Extensible records** suit narrow function arguments
  (`viewName : { a | name : String } -> Html msg`). Do not use them to imitate
  inheritance in the model; errors become unreadable.
- **Remote data**: a three- or four-constructor type in the app is often
  enough; `krisajenkins/remotedata` adds `map`, `andThen` and friends when
  many requests need them.
- **Derived data**: store sources, derive the rest. Keeping both `filterText`
  and a normalized copy, or both `selectedId` and `selectedItem`, invites
  drift. Cache derived values only when profiling shows the need.

## Scaling an application

- Organize modules around a central type (`Card`, `Page.Home`), not into
  Model/Update/View files. Evan advises growing files rather than splitting
  early; the fleet's limit is about 500 lines per source file, so split along
  types when a file approaches it.
- Avoid nested TEA "components" by default. Every child `Model`/`Msg`/`update`
  adds `Html.map`, wrapper messages and child-to-parent signaling. Use a view
  function that takes data and message constructors:
  `viewToggle : { checked : Bool, onToggle : Bool -> msg } -> Html msg`.
  Give a unit its own `update` only when it has real internal state and
  lifecycle, such as a page.
- Single-page apps use a module per page with its own `Model`, `Msg`, `init`,
  `update`, `view` and `subscriptions`, and a root `Model` that is a custom
  type of pages (`Home Home.Model | Article Article.Model | NotFound`). Shared
  data (session, credentials, the `Nav.Key`) lives in a `Session` or `Shared`
  value passed to pages.
- Keep `update` branches short: each calls a named function. A helper of type
  `(model -> ( model, Cmd msg )) -> ( model, Cmd msg ) -> ( model, Cmd msg )`
  chains steps.
- The Effect pattern returns plain data (`type Effect = SaveFilter String |
  FetchCards`) from `update` and converts it to `Cmd` at the root. It makes
  `update` testable, because `Cmd` values are opaque, at the cost of one more
  layer. elm-program-test supports it; Elm Land's `Effect` module follows it.

## Effects and time

- `Task.perform` is for tasks that cannot fail (`Time.now`, `Time.here`,
  `Process.sleep`); `Task.attempt` for tasks that can, giving a `Result`. A
  single HTTP request is already a `Cmd` (`Http.get`, `Http.post`); use
  `Http.task` only to chain requests.
- `Cmd.batch` runs commands in no guaranteed order. Sequence dependent work
  with `Task.andThen` or through messages.
- `subscriptions` is a pure function of the model, recomputed after every
  update. Return `Sub.none` for states that need nothing; that is the only way
  to stop a subscription.
- Repeating work uses `Time.every` in `subscriptions`, gated on state.
  `Process.sleep` is for one-shot delays such as debouncing; it cannot be
  canceled, so keep a counter in the model and ignore stale replies.
- `Time.Posix` is UTC milliseconds. Rendering local time needs a `Time.Zone`
  from `Task.perform GotZone Time.here`, which arrives after `init`, so start
  with `Time.utc`. Calendar dates and named zones need packages such as
  `justinmimbs/date` and `justinmimbs/timezone-data` (*researched*).
- Randomness: store the `Seed` returned by `Random.step` and use it next
  time, or use `Random.generate`. Reusing `Random.initialSeed 42` produces the
  same value forever.

## JavaScript interop

- **Flags**: type them as `Decode.Value` and decode in `init`.
- **Ports**: put them in one `port module`, prefer one outgoing and one
  incoming port carrying tagged JSON over a port per JavaScript function
  (see [Ports.elm](../examples/src/Ports.elm)), and design request and
  response pairs with a correlation id when several requests can be in
  flight. Ports carry `Bool`, `Int`, `Float`, `String`, `Maybe`, `List`,
  `Array`, records, tuples and `Json.Encode.Value`, not custom types or
  functions. They are asynchronous and not allowed in published packages.
  Unused ports are removed by dead-code elimination, so a port JavaScript
  expects must actually be used in Elm.
- **Custom elements** fit UI-shaped interop (maps, editors, charts): wrap the
  widget as a Web Component and drive it from `view` with properties and
  `Html.Events.on` handlers, keeping data flow declarative.
- Kernel (native) JavaScript is limited to `elm/*` and `elm-explorations/*`
  packages. Do not suggest `Native.` modules or forks that rely on them.

## Rendering and the DOM

- `Html.Lazy.lazy` skips work only when every argument is the same JavaScript
  reference as last time. Pass stable model fields or primitives; a record,
  list or lambda built inside `view` defeats it on every render. Measure.
- `Html.Keyed` gives list children stable identities (`( id, html )`), so
  reordering or inserting keeps focus, scroll and input state with the right
  item. Keys must be unique strings.
- Do not do heavy sorting, filtering or parsing in `view` for large data;
  derive once in `update` or use `lazy`.
- Bind text inputs to exactly what the user typed. If `update` stores a
  transformed value (trimmed, uppercased) and `view` feeds it back through
  `value`, the DOM is reset and the caret jumps. Normalize on use, blur or
  submit instead (*researched* browser behavior). When a requirement says to
  store the normalized value, store the raw text and derive the normalized
  form with one function (as the example's `normalize` does), or keep both
  fields updated in the same branch. Leaving the input uncontrolled (no
  `value`) also avoids the jump, but then the model can no longer clear or
  set the field.
- `Html.Attributes.value`, `checked` and `selected` set live DOM properties.
  `attribute` sets HTML attributes (`aria-*`, `data-*`); `property` sets
  arbitrary properties, which is how custom elements receive data.
- `onClick` and `onSubmit` cannot prevent defaults. Use
  `Html.Events.preventDefaultOn` or `Html.Events.custom`.
- Duplicate element ids break `Browser.Dom.focus` and label `for` links.
  Derive ids from unique keys, and handle `Browser.Dom.NotFound`.
- elm-ui (`mdgriffith/elm-ui` 1.1.8, 2020) is stable but frozen, and elm-css
  is low-activity (*researched*). Plain `elm/html` with CSS is the
  conservative default.

## Testing

- `elm-explorations/test` (2.2.1) provides `Test`, `Expect` and `Fuzz`. Run it
  with the runner that matches the compiler (see the toolchain reference).
- Test decoders against real payloads, smart constructors, parsers and the
  branching logic in `update` (assert on the returned model). Use fuzz tests
  for properties: round trips, `parse (toString x) == Ok x`, idempotence.
- Do not spend tests on what the compiler guarantees: exhaustiveness, type
  shapes, invariants made unrepresentable by opaque types.
- `avh4/elm-program-test` (*researched*, 3.x) drives a whole program with
  simulated clicks, HTTP and ports and asserts on the rendered HTML.

## Packages

For published packages: design from real examples, keep the API small, expose
every type users must name in annotations, write `{-| -}` documentation for
every exposed item with `@docs` in the module comment, use explicit exposing
lists, and let `elm bump` enforce semantic versioning. Packages cannot contain
ports or kernel code. Read the official
[design guidelines](https://package.elm-lang.org/help/design-guidelines) and
[documentation format](https://package.elm-lang.org/help/documentation-format)
before publishing.
