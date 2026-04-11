defmodule AndaWeb.CoreComponents do
  @moduledoc """
  Provides core UI components.

  At first glance, this module may seem daunting, but its goal is to provide
  core building blocks for your application, such as tables, forms, and
  inputs. The components consist mostly of markup and are well-documented
  with doc strings and declarative assigns. You may customize and style
  them in any way you want, based on your application growth and needs.

  The foundation for styling is Tailwind CSS, a utility-first CSS framework,
  augmented with daisyUI, a Tailwind CSS plugin that provides UI components
  and themes. Here are useful references:

    * [daisyUI](https://daisyui.com/docs/intro/) - a good place to get
      started and see the available components.

    * [Tailwind CSS](https://tailwindcss.com) - the foundational framework
      we build on. You will use it for layout, sizing, flexbox, grid, and
      spacing.

    * [Heroicons](https://heroicons.com) - see `icon/1` for usage.

    * [Phoenix.Component](https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html) -
      the component system used by Phoenix. Some components, such as `<.link>`
      and `<.form>`, are defined there.

  """
  use Phoenix.Component
  use Gettext, backend: AndaWeb.Gettext

  alias Phoenix.LiveView.JS

  @doc """
  Renders flash notices.

  ## Examples

      <.flash kind={:info} flash={@flash} />
      <.flash kind={:info} phx-mounted={show("#flash")}>Welcome Back!</.flash>
  """
  attr :id, :string, doc: "the optional id of flash container"
  attr :flash, :map, default: %{}, doc: "the map of flash messages to display"
  attr :title, :string, default: nil
  attr :kind, :atom, values: [:info, :error], doc: "used for styling and flash lookup"
  attr :rest, :global, doc: "the arbitrary HTML attributes to add to the flash container"

  slot :inner_block, doc: "the optional inner block that renders the flash message"

  def flash(assigns) do
    assigns = assign_new(assigns, :id, fn -> "flash-#{assigns.kind}" end)

    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> hide("##{@id}")}
      role="alert"
      class="toast toast-top toast-end z-50"
      {@rest}
    >
      <div class={[
        "alert w-80 sm:w-96 max-w-80 sm:max-w-96 text-wrap",
        @kind == :info && "alert-info",
        @kind == :error && "alert-error"
      ]}>
        <.icon :if={@kind == :info} name="hero-information-circle" class="size-5 shrink-0" />
        <.icon :if={@kind == :error} name="hero-exclamation-circle" class="size-5 shrink-0" />
        <div>
          <p :if={@title} class="font-semibold">{@title}</p>
          <p>{msg}</p>
        </div>
        <div class="flex-1" />
        <button type="button" class="group self-start cursor-pointer" aria-label={gettext("close")}>
          <.icon name="hero-x-mark" class="size-5 opacity-40 group-hover:opacity-70" />
        </button>
      </div>
    </div>
    """
  end

  @doc """
  Renders a simple form.

  ## Examples

      <.simple_form for={@form} phx-change="validate" phx-submit="save">
        <.input field={@form[:email]} label="Email"/>
        <.input field={@form[:username]} label="Username" />
        <:actions>
          <.button>Save</.button>
        </:actions>
      </.simple_form>
  """
  attr :for, :any, required: true, doc: "the data structure for the form"
  attr :as, :any, default: nil, doc: "the server side parameter to collect all input under"

  attr :rest, :global,
    include: ~w(autocomplete name rel action enctype method novalidate target multipart),
    doc: "the arbitrary HTML attributes to apply to the form tag"

  slot :inner_block, required: true
  slot :actions, doc: "the slot for form actions, such as a submit button"

  def simple_form(assigns) do
    ~H"""
    <.form :let={f} for={@for} as={@as} {@rest}>
      <div class=" space-y-8 bg-base">
        {render_slot(@inner_block, f)}
        <div :for={action <- @actions} class="mt-2 flex items-center justify-between gap-6">
          {render_slot(action, f)}
        </div>
      </div>
    </.form>
    """
  end

  @doc """
  Renders a modal.

  ## Examples

      <.modal id="confirm-modal">
        This is a modal.
      </.modal>

  JS commands may be passed to the `:on_cancel` to configure
  the closing/cancel event, for example:

      <.modal id="confirm" on_cancel={JS.navigate(~p"/posts")}>
        This is another modal.
      </.modal>

  """
  attr :id, :string, required: true
  attr :show, :boolean, default: false
  attr :on_cancel, JS, default: %JS{}
  slot :inner_block, required: true

  def modal(assigns) do
    ~H"""
    <div
      id={@id}
      phx-mounted={@show && show_modal(@id)}
      phx-remove={hide_modal(@id)}
      data-cancel={JS.exec(@on_cancel, "phx-remove")}
      class="relative z-50 hidden"
    >
      <div
        id={"#{@id}-bg"}
        class="bg-base-200/80 fixed inset-0 transition-opacity"
        aria-hidden="true"
      />
      <div
        class="fixed inset-0 overflow-y-auto"
        aria-labelledby={"#{@id}-title"}
        aria-describedby={"#{@id}-description"}
        role="dialog"
        aria-modal="true"
        tabindex="0"
      >
        <div class="flex min-h-full items-center justify-center">
          <div class="w-screen max-w-2xl p-2 md:p-4 lg:py-8">
            <.focus_wrap
              id={"#{@id}-container"}
              phx-window-keydown={JS.exec("data-cancel", to: "##{@id}")}
              phx-key="escape"
              phx-click-away={JS.exec("data-cancel", to: "##{@id}")}
              class="shadow-zinc-700/10 ring-zinc-700/10 relative hidden rounded-md bg-base-100 p-6 md:p-10 shadow-lg ring-1 transition"
            >
              <div class="absolute top-6 right-5">
                <button
                  phx-click={JS.exec("data-cancel", to: "##{@id}")}
                  type="button"
                  class="-m-3 flex-none p-3 opacity-20 hover:opacity-40"
                  aria-label={gettext("close")}
                >
                  <.icon name="hero-x-mark-solid" class="h-5 w-5" />
                </button>
              </div>
              <div id={"#{@id}-content"}>
                {render_slot(@inner_block)}
              </div>
            </.focus_wrap>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def show_modal(js \\ %JS{}, id) when is_binary(id) do
    js
    |> JS.show(to: "##{id}")
    |> JS.show(
      to: "##{id}-bg",
      time: 300,
      transition: {"transition-all transform ease-out duration-300", "opacity-0", "opacity-100"}
    )
    |> show("##{id}-container")
    |> JS.add_class("overflow-hidden", to: "body")
    |> JS.focus_first(to: "##{id}-content")
  end

  def hide_modal(js \\ %JS{}, id) do
    js
    |> JS.hide(
      to: "##{id}-bg",
      transition: {"transition-all transform ease-in duration-200", "opacity-100", "opacity-0"}
    )
    |> hide("##{id}-container")
    |> JS.hide(to: "##{id}", transition: {"block", "block", "hidden"})
    |> JS.remove_class("overflow-hidden", to: "body")
    |> JS.pop_focus()
  end

  @doc """
  Renders a button with navigation support.

  ## Examples

      <.button>Send!</.button>
      <.button phx-click="go" variant="primary">Send!</.button>
      <.button navigate={~p"/"}>Home</.button>
  """
  attr :rest, :global, include: ~w(href navigate patch method download name value disabled)
  attr :class, :string
  attr :variant, :string, values: ~w(primary)
  slot :inner_block, required: true

  def button(%{rest: rest} = assigns) do
    variants = %{"primary" => "btn-primary", nil => "btn-primary"}

    assigns =
      assign_new(assigns, :class, fn ->
        ["btn", Map.fetch!(variants, assigns[:variant])]
      end)

    if rest[:href] || rest[:navigate] || rest[:patch] do
      ~H"""
      <.link class={@class} {@rest}>
        {render_slot(@inner_block)}
      </.link>
      """
    else
      ~H"""
      <button class={@class} {@rest}>
        {render_slot(@inner_block)}
      </button>
      """
    end
  end

  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :value, :any

  attr :field, Phoenix.HTML.FormField,
    doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :errors, :list, default: []
  attr :class, :string, default: nil, doc: "the input class to use over defaults"
  attr :error_class, :string, default: nil, doc: "the input error class to use over defaults"
  attr :num_inputs, :integer, default: 1

  attr :rest, :global,
    include: ~w(accept autocomplete capture cols disabled form list max maxlength min minlength
                multiple pattern placeholder readonly required rows size step)

  def textgroup(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns =
      assigns
      |> assign(field: nil, id: assigns.id || field.id)
      |> assign(:errors, Enum.map(errors, &translate_error(&1)))
      |> assign_new(:name, fn -> field.name <> "[]" end)
      |> assign_new(:value, fn ->
        if is_bitstring(field.value), do: [field.value], else: field.value
      end)

    ~H"""
    <div class="text-sm">
      <label for={@id}>{@label}</label>
      <div class="flex flex-col gap-2">
        <div :for={index <- 0..(@num_inputs - 1)} class="">
          <input
            type="text"
            id={"#{@id}-#{index}"}
            name={@name}
            value={Enum.at(@value, index, "")}
            class="input w-3xs"
            {@rest}
          />
        </div>
      </div>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  @doc """
  Renders an input with label and error messages.

  A `Phoenix.HTML.FormField` may be passed as argument,
  which is used to retrieve the input name, id, and values.
  Otherwise all attributes may be passed explicitly.

  ## Types

  This function accepts all HTML input types, considering that:

    * You may also set `type="select"` to render a `<select>` tag

    * `type="checkbox"` is used exclusively to render boolean values

    * For live file uploads, see `Phoenix.Component.live_file_input/1`

  See https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input
  for more information. Unsupported types, such as hidden and radio,
  are best written directly in your templates.

  ## Examples

      <.input field={@form[:email]} type="email" />
      <.input name="my-input" errors={["oh no!"]} />
  """
  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :value, :any

  attr :type, :string,
    default: "text",
    values:
      ~w(checkbox color date datetime-local email file month number password
               search select tel text textarea time url week checkgroup radiogroup textgroup hidden multicheckbox)

  attr :field, Phoenix.HTML.FormField,
    doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :errors, :list, default: []
  attr :saved, :boolean, default: false
  attr :checked, :boolean, doc: "the checked flag for checkbox inputs"
  attr :prompt, :string, default: nil, doc: "the prompt for select inputs"
  attr :options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2"
  attr :multiple, :boolean, default: false, doc: "the multiple flag for select inputs"
  attr :class, :string, default: nil, doc: "the input class to use over defaults"
  attr :error_class, :string, default: nil, doc: "the input error class to use over defaults"
  attr :num_inputs, :integer, default: 1
  attr :col, :boolean, default: false
  attr :item, :string

  attr :rest, :global,
    include: ~w(accept autocomplete capture cols disabled form list max maxlength min minlength
                multiple pattern placeholder readonly required rows size step)

  def input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(errors, &translate_error(&1)))
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> input()
  end

  def input(%{type: "checkbox"} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn ->
        Phoenix.HTML.Form.normalize_value("checkbox", assigns[:value])
      end)

    ~H"""
    <div class="fieldset mb-2">
      <label>
        <input type="hidden" name={@name} value="false" disabled={@rest[:disabled]} />
        <span class="label">
          <input
            type="checkbox"
            id={@id}
            name={@name}
            value="true"
            checked={@checked}
            class={@class || "checkbox checkbox-sm"}
            {@rest}
          />{@label}
        </span>
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(%{type: "multicheckbox"} = assigns) do
    ~H"""
    <input
      type="checkbox"
      id={"#{@name}-#{@v}"}
      name={@name}
      value={@item}
      checked={@item in @value}
      class={"checkbox #{@class}"}
      {@rest}
    />
    """
  end

  def input(%{type: "radiogroup"} = assigns) do
    ~H"""
    <fieldset class="fieldset mb-2 w-full">
      <label class="label mb-1">{@label}</label>
      <input type="hidden" name={@name} value="" />
      <div class={["flex", if(@col, do: "flex-col", else: "flex-row"), "flex-wrap gap-5 w-full"]}>
        <label :for={option <- @options} class="label text-base min-w-40">
          <input
            type="radio"
            id={"#{@id}-#{@name}-#{option.value}"}
            name={@name}
            value={option.value}
            checked={option.value == @value}
            class="radio radio-sm"
            {@rest}
          />
          <div>
            <div>
              {option.label}
            </div>
            <div :if={Map.get(option, :helptext)} class="text-xs">
              {Map.get(option, :helptext)}
            </div>
          </div>
        </label>
      </div>
      <.error :for={msg <- @errors}>{msg}</.error>
    </fieldset>
    """
  end

  def input(%{type: "select"} = assigns) do
    ~H"""
    <div class="fieldset mb-2">
      <label>
        <span :if={@label} class="label mb-1">{@label}</span>
        <select
          id={@id}
          name={@name}
          class={[@class, "select w-full", @errors != [] && (@error_class || "select-error")]}
          multiple={@multiple}
          {@rest}
        >
          <option :if={@prompt} value="" disabled selected={@value == ""}>{@prompt}</option>
          {Phoenix.HTML.Form.options_for_select(@options, @value)}
        </select>
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(%{type: "textarea"} = assigns) do
    ~H"""
    <div class="fieldset mb-2">
      <label>
        <span :if={@label} class="label mb-1">{@label}</span>
        <textarea
          id={@id}
          name={@name}
          class={[
            @class,
            "w-full textarea",
            @errors != [] && (@error_class || "textarea-error")
          ]}
          {@rest}
        >{Phoenix.HTML.Form.normalize_value("textarea", @value)}</textarea>
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(%{type: "checkgroup"} = assigns) do
    ~H"""
    <div class="text-sm my-3">
      <label :if={@label} for={@id}>{@label}</label>
      <div class="grid grid-cols-1 gap-1 text-sm items-baseline mt-3">
        <input type="hidden" name={@name} value="" />
        <div :for={{label, value} <- @options} class="flex items-center gap-2">
          <label for={"#{@name}-#{value}"} class="label">
            <input
              type="checkbox"
              id={"#{@name}-#{value}"}
              name={@name}
              value={value}
              checked={value in @value}
              class="checkbox"
              {@rest}
            />
            {label}
          </label>
        </div>
      </div>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(%{type: "hidden"} = assigns) do
    ~H"""
    <input
      type={@type}
      name={@name}
      id={@id}
      value={Phoenix.HTML.Form.normalize_value(@type, @value)}
      class={[
        @class,
        "w-full input",
        @errors != [] && (@error_class || "input-error")
      ]}
      {@rest}
    />
    <.error :for={msg <- @errors}>{msg}</.error>
    """
  end

  def input(%{type: "radio"} = assigns) do
    ~H"""
    <div class="fieldset mb-2">
      <label>
        <span :if={@label} class="label mb-1">{@label}</span>
        <input
          type={@type}
          name={@name}
          id={@id}
          value={Phoenix.HTML.Form.normalize_value(@type, @value)}
          class={[
            @class,
            "radio",
            @errors != [] && (@error_class || "input-error")
          ]}
          {@rest}
        />
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
      <.saved :if={Enum.empty?(@errors) && @saved} />
    </div>
    """
  end

  # All other inputs text, datetime-local, url, password, etc. are handled here...
  def input(assigns) do
    ~H"""
    <div class="fieldset mb-2">
      <label>
        <span :if={@label} class="label mb-1">{@label}</span>
        <input
          type={@type}
          name={@name}
          id={@id}
          value={Phoenix.HTML.Form.normalize_value(@type, @value)}
          class={[
            @class,
            "w-full input",
            @errors != [] && (@error_class || "input-error")
          ]}
          {@rest}
        />
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
      <.saved :if={Enum.empty?(@errors) && @saved} />
    </div>
    """
  end

  @doc """
  Generate a checkbox group for multi-select.
  """
  attr :id, :any
  attr :name, :any
  attr :label, :string, default: nil

  attr :field, Phoenix.HTML.FormField,
    doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :errors, :list
  attr :options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2"
  attr :rest, :global, include: ~w(disabled form readonly)
  attr :class, :string, default: nil

  def checkgroup(assigns) do
    new_assigns =
      assigns
      |> assign(:multiple, true)
      |> assign(:type, "checkgroup")

    input(new_assigns)
  end

  # Helper used by inputs to generate form errors
  defp error(assigns) do
    ~H"""
    <p class="mt-1.5 flex gap-2 items-center text-sm text-error">
      <.icon name="hero-exclamation-circle" class="size-5" />
      {render_slot(@inner_block)}
    </p>
    """
  end

  attr :class, :string, default: ""

  def saved(assigns) do
    ~H"""
    <p class={"mt-1.5 flex gap-2 items-center text-sm text-success fade-out #{@class}"}>
      <.icon name="hero-check-circle" class="size-5" /> Lagra!
    </p>
    """
  end

  def loading(assigns) do
    ~H"""
    <p class={"mt-1.5 flex gap-2 items-center text-sm text-success fade-out #{@class}"}>
      <span class="loading loading-spinner size-6 flex-none hidden m-2"></span> Lagrer...
    </p>
    """
  end

  @doc """
  Renders a header with title.
  """
  slot :inner_block, required: true
  slot :subtitle
  slot :actions

  def header(assigns) do
    ~H"""
    <header class={[@actions != [] && "flex items-center justify-between gap-6", "pb-4"]}>
      <div>
        <h1 class="text-xl font-semibold leading-8">
          {render_slot(@inner_block)}
        </h1>
        <p :if={@subtitle != []} class="text-sm text-base-content/70">
          {render_slot(@subtitle)}
        </p>
      </div>
      <div class="flex-none">{render_slot(@actions)}</div>
    </header>
    """
  end

  @doc """
  Renders a table with generic styling.

  ## Examples

      <.table id="users" rows={@users}>
        <:col :let={user} label="id">{user.id}</:col>
        <:col :let={user} label="username">{user.username}</:col>
      </.table>
  """
  attr :id, :string, required: true
  attr :rows, :list, required: true
  attr :row_id, :any, default: nil, doc: "the function for generating the row id"
  attr :row_click, :any, default: nil, doc: "the function for handling phx-click on each row"

  attr :row_item, :any,
    default: &Function.identity/1,
    doc: "the function for mapping each row before calling the :col and :action slots"

  slot :col, required: true do
    attr :label, :string
  end

  slot :action, doc: "the slot for showing user actions in the last table column"

  def table(assigns) do
    assigns =
      with %{rows: %Phoenix.LiveView.LiveStream{}} <- assigns do
        assign(assigns, row_id: assigns.row_id || fn {id, _item} -> id end)
      end

    ~H"""
    <table class="table">
      <thead>
        <tr>
          <th :for={col <- @col}>{col[:label]}</th>
          <th :if={@action != []}>
            <span class="sr-only">{gettext("Actions")}</span>
          </th>
        </tr>
      </thead>
      <tbody id={@id} phx-update={is_struct(@rows, Phoenix.LiveView.LiveStream) && "stream"}>
        <tr :for={row <- @rows} id={@row_id && @row_id.(row)}>
          <td
            :for={col <- @col}
            phx-click={@row_click && @row_click.(row)}
            class={@row_click && "hover:cursor-pointer"}
          >
            {render_slot(col, @row_item.(row))}
          </td>
          <td :if={@action != []} class="w-0 font-semibold">
            <div class="flex gap-4">
              <%= for action <- @action do %>
                {render_slot(action, @row_item.(row))}
              <% end %>
            </div>
          </td>
        </tr>
      </tbody>
    </table>
    """
  end

  @doc """
  Renders a data list.

  ## Examples

      <.list>
        <:item title="Title">{@post.title}</:item>
        <:item title="Views">{@post.views}</:item>
      </.list>
  """
  slot :item, required: true do
    attr :title, :string, required: true
  end

  def list(assigns) do
    ~H"""
    <ul class="list">
      <li :for={item <- @item} class="list-row">
        <div class="list-col-grow">
          <div class="font-bold">{item.title}</div>
          <div>{render_slot(item)}</div>
        </div>
      </li>
    </ul>
    """
  end

  @doc """
  Renders a [Heroicon](https://heroicons.com).

  Heroicons come in three styles – outline, solid, and mini.
  By default, the outline style is used, but solid and mini may
  be applied by using the `-solid` and `-mini` suffix.

  You can customize the size and colors of the icons by setting
  width, height, and background color classes.

  Icons are extracted from the `deps/heroicons` directory and bundled within
  your compiled app.css by the plugin in `assets/vendor/heroicons.js`.

  ## Examples

      <.icon name="hero-x-mark" />
      <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
  """
  attr :name, :string, required: true
  attr :class, :string, default: "size-4"
  attr :rest, :global

  def icon(%{name: "hero-" <> _} = assigns) do
    ~H"""
    <span class={[@name, @class]} {@rest} />
    """
  end

  ## JS Commands

  def show(js \\ %JS{}, selector) do
    JS.show(js,
      to: selector,
      time: 300,
      transition:
        {"transition-all ease-out duration-300",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
  end

  def hide(js \\ %JS{}, selector) do
    JS.hide(js,
      to: selector,
      time: 200,
      transition:
        {"transition-all ease-in duration-200", "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
  end

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, opts}) do
    # When using gettext, we typically pass the strings we want
    # to translate as a static argument:
    #
    #     # Translate the number of files with plural rules
    #     dngettext("errors", "1 file", "%{count} files", count)
    #
    # However the error messages in our forms and APIs are generated
    # dynamically, so we need to translate them by calling Gettext
    # with our gettext backend as first argument. Translations are
    # available in the errors.po file (as we use the "errors" domain).
    if count = opts[:count] do
      Gettext.dngettext(AndaWeb.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(AndaWeb.Gettext, "errors", msg, opts)
    end
  end

  @doc """
  Translates the errors for a field from a keyword list of errors.
  """
  def translate_errors(errors, field) when is_list(errors) do
    for {^field, {msg, opts}} <- errors, do: translate_error({msg, opts})
  end

  attr :title, :string, required: true
  attr :description, :string
  attr :id, :string
  slot :content
  slot :controls

  def section(assigns) do
    ~H"""
    <div id={@id} class="card bg-base-100 shadow-sm">
      <div class="divide-(--color-base-300) divide-y-2 divide-dotted flex flex-col">
        <div>
          <div class="flex">
            <div class="flex-grow">
              <h2 class="text-xl font-bold px-3 lg:px-6 py-6">{@title}</h2>
              <p :if={@description} class="text-md pb-4 px-6">
                {@description}
              </p>
            </div>
            <div :if={@controls} class="p-6">
              {render_slot(@controls)}
            </div>
          </div>
        </div>
        <div
          :for={content <- @content}
          class="px-3 lg:px-6 py-6 lg:py-8"
        >
          {render_slot(content)}
        </div>
      </div>
    </div>
    """
  end

  attr :src, :string, required: true
  attr :type, :string, required: true
  attr :size, :integer, default: 300
  attr :aspect_ratio, :float, default: nil
  attr :id, :string
  attr :rest, :global

  def simple_media_view(assigns) do
    ~H"""
    <div :if={!is_nil(@src)} id={@id} {@rest}>
      <img
        :if={String.starts_with?(@type, "image")}
        loading="lazy"
        class="object-contain object-left"
        style={"aspect-ratio: auto #{@aspect_ratio || ""}; width: 100%; max-width: #{@size}px; max-height: #{@size}px"}
        src={@src}
      />
      <video
        :if={String.starts_with?(@type, "video")}
        loading="lazy"
        class="object-contain object-left"
        controls
        style={"aspect-ratio: auto #{@aspect_ratio || ""}; width: 100%; max-width: #{@size}px; max-height: #{@size}px"}
      >
        <source src={@src} type={@type} />
      </video>
      <audio
        :if={String.starts_with?(@type, "audio")}
        loading="lazy"
        class="object-contain"
        style={"width: 100%; max-width: #{@size}px;"}
        controls
        controlslist="nodownload nofullscreen noremoteplayback"
        src={@src}
      />
    </div>
    """
  end

  attr :src, :string, required: true
  attr :type, :string, required: true
  attr :size, :integer, default: 300
  attr :aspect_ratio, :float, default: nil
  attr :id, :string
  attr :rest, :global

  def media_view(assigns) do
    ~H"""
    <div :if={!is_nil(@src)} id={@id} {@rest} phx-hook=".MediaView">
      <div style={"aspect-ratio: auto #{@aspect_ratio || ""}; _width: 100%; max-width: #{@size}px; max-height: #{@size}px"}>
        <a :if={String.starts_with?(@type, "image")} href={"#show-#{@id}"}>
          <img
            loading="lazy"
            class="object-contain object-left max-w-full max-h-full"
            src={@src}
          />
        </a>
        <a
          :if={String.starts_with?(@type, "video")}
          class="block relative w-fit h-fit"
          href={"#show-#{@id}"}
        >
          <video
            loading="lazy"
            class="object-contain object-left max-w-full max-h-full"
          >
            <source src={@src} type={@type} />
          </video>
          <.icon
            name="hero-play-solid"
            class="block absolute bg-white/70 h-12 w-12"
            style="top: 50%; left: 50%; transform: translate(-50%, -50%);"
          />
        </a>
      </div>

      <audio
        :if={String.starts_with?(@type, "audio")}
        loading="lazy"
        class="object-contain"
        style={"width: 100%; max-width: #{@size}px;"}
        controls
        controlslist="nodownload nofullscreen noremoteplayback"
        src={@src}
      />
      <dialog
        class="backdrop:bg-gray-900/70 max-w-3xl w-fit max-h-full max-w-full bg-transparent"
        style="top: 50%; left: 50%; transform: translate(-50%, -50%);"
      >
        <div class=" flex flex-col items-center p-2">
          <button class="btn btn-square btn-soft mb-2 self-end">
            <.icon name="hero-x-mark" />
          </button>
          <img
            :if={String.starts_with?(@type, "image")}
            loading="lazy"
            class="object-contain object-left max-h-[calc(100vh-70px)] max-w-[calc(100vw-20px)]"
            src={@src}
          />
          <video
            :if={String.starts_with?(@type, "video")}
            loading="lazy"
            controls
            controlslist="nodownload nofullscreen noremoteplayback"
            class="object-contain object-left max-h-[calc(100vh-70px)] max-w-[calc(100vw-20px)]"
          >
            <source src={@src} type={@type} />
          </video>
        </div>
      </dialog>
    </div>
    <script :type={Phoenix.LiveView.ColocatedHook} name=".MediaView">
      export default {
        mounted() {
          const dialog = this.el.querySelector("dialog")
          const video = this.el.querySelector("dialog video")
          const button = this.el.querySelector("dialog button")

          this.handleDialogClose = () => {
            if(window.location.hash) {
              const url = new URL(window.location)
              url.hash = ""
              //window.history.replaceState({}, "", url)
              window.history.back()
            }
            if(video) {
              video.pause()
              video.currentTime = 0
            }
          }

          this.handleButtonClick = () => {
            dialog.close()
          }

          this.handleHashChange = () => {
            if(window.location.hash === id) {
              dialog.showModal()
            } else {
              dialog.close()
            }
          }

          const id = "#show-"+this.el.id
          if(window.location.hash === id) {
            dialog.showModal()
          }

          dialog.addEventListener("close", this.handleDialogClose)
          button.addEventListener("click", this.handleButtonClick)
          window.addEventListener("hashchange", this.handleHashChange)
        },
        destroyed() {
          window.removeEventListener("hashchange", this.handleHashChange)
        }
      }
    </script>
    """
  end

  attr :question, Anda.Contest.Question, required: true
  slot :inner_block

  def question(assigns) do
    ~H"""
    <div class="flex w-full">
      <div :if={@question.rank} class="pr-2 shrink font-bold">
        {@question.rank}.
      </div>
      <div class="grow">
        <div class="flex">
          <div class="grow text-md mb-4 font-medium markdown-container">
            {Phoenix.HTML.raw(MDEx.to_html!(@question.text, render: [hardbreaks: true]))}
          </div>
          <div :if={@question.points} class="shrink text-gray-400 pl-2">({@question.points}p)</div>
        </div>

        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  attr :key, :string
  attr :sort_order, :string
  attr :title, :string
  attr :rest, :global
  def sortable_header(assigns) do
    assigns = assign(assigns, this_asc: "#{assigns.key}_asc", this_desc: "#{assigns.key}_desc")

    ~H"""
    <th
      class="hover:bg-base-200/50 hover:cursor-pointer"
      phx-click="set_sort_order"
      phx-value-sort_order={if @sort_order === @this_asc, do: @this_desc, else: @this_asc}
      {@rest}
    >
      {@title}
      <span class="w-4 inline-block">
        <.icon :if={@sort_order == @this_desc} name="hero-chevron-up" />
        <.icon :if={@sort_order == @this_asc} name="hero-chevron-down" />
      </span>
    </th>
    """
  end
end
