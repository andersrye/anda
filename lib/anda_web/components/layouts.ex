defmodule AndaWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use AndaWeb, :html

  # Embed all files in layouts/* within this module.
  # The default root.html.heex file contains the HTML
  # skeleton of your application, namely HTML headers
  # and other static content.
  embed_templates "layouts/*"

  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :show_header, :boolean, default: true

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://hexdocs.pm/phoenix/scopes.html)"

  slot :inner_block, required: true

  slot :breadcrumb, required: false

  def app(assigns) do
    ~H"""
    <div class="main-container flex flex-col font-serif">
      <header :if={@show_header} class="navbar px-4 sm:px-6 lg:px-8 shadow-sm z-10">
        <div class="flex-1">
          <a href="/" class="flex-1 flex w-fit items-center gap-2">
            Anders sin quizgreie
          </a>
        </div>

        <div class="flex-none">
          <details class="dropdown dropdown-end">
            <summary class="btn m-1 btn-outline btn-square bg-base-200">
              <.icon name="hero-user-circle" />
            </summary>
            <div class="dropdown-content  bg-base-100 rounded-box z-1 w-52 p-2 shadow-sm z-100">
              <div :if={@current_scope} class="text-sm p-3">
                Logget inn som {@current_scope.user.email}
                <hr class="h-px my-2 bg-neutral border-0" />
              </div>
              <ul class="menu w-full">
                <%= if @current_scope do %>
                  <li>
                    <.link href={~p"/users/settings"}>Kontoinnstillinger</.link>
                  </li>
                  <li>
                    <.link href={~p"/users/log-out"} method="delete">Logg ut</.link>
                  </li>
                <% else %>
                  <li>
                    <.link href={~p"/users/register"}>Lag konto</.link>
                  </li>
                  <li>
                    <.link href={~p"/users/log-in"}>Logg inn</.link>
                  </li>
                <% end %>
              </ul>
            </div>
          </details>
        </div>
      </header>

      <main class="px-4 pb-20 sm:px-6 lg:px-8 bg-base-200 flex-grow">
        <!--<div :if={@breadcrumb != [] && @show_header} class="pt-4 breadcrumbs text-sm">
          <ul>
            <li :for={item <- @breadcrumb}>{render_slot(item)}</li>
          </ul>
        </div>-->
        <div class="mx-auto max-w-2xl space-y-4">
          {render_slot(@inner_block)}
        </div>
      </main>
    </div>

    <.flash_group flash={@flash} />
    """
  end

  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :show_header, :boolean, default: true

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://hexdocs.pm/phoenix/scopes.html)"

  attr :current_tab, :atom, required: true
  attr :quiz, :map, required: true

  slot :inner_block, required: true

  slot :breadcrumb, required: false

  def quiz_app(assigns) do
    {mode_text, mode_status} =
      case assigns.quiz.mode do
        "hidden" -> {"Skjult", "status-info"}
        "open" -> {"Åpen", "status-success"}
        "closed" -> {"Stengt", "status-error"}
        _ -> {"??", "status-neutral"}
      end

    assigns = assign(assigns, mode_text: mode_text, mode_status: mode_status)

    ~H"""
    <.app current_scope={@current_scope} show_header={@show_header} flash={@flash}>
      <div :if={@show_header} class="flex mt-6">
        <.header>
          {@quiz.title}
        </.header>
        <span class="badge badge-sm badge-ghost m-1">
          <span class={"status #{@mode_status}"}></span>
          {@mode_text}
        </span>
        <span class="flex-grow"></span>
        <.link
          class="btn btn-xs btn-outline m-3 place-self-end"
          href={~p"/quiz/#{@quiz.slug}"}
          target="_blank"
        >
          Åpne quiz <.icon name="hero-arrow-top-right-on-square" />
        </.link>
      </div>
      <div
        :if={@show_header}
        id="header-menu"
        phx-hook=".MenuScroll"
        role="tablist"
        class="tabs tabs-border w-full overflow-x-auto overflow-y-clip flex-nowrap mb-8"
        style="box-shadow: 0 2px 2px -2px gray"
      >
        <.link
          role="tab"
          class={["tab", @current_tab == :edit && "tab-active"]}
          navigate={~p"/admin/quiz/#{@quiz.id}/edit"}
        >
          Rediger
        </.link>
        <.link
          role="tab"
          class={["tab", @current_tab == :score && "tab-active"]}
          navigate={~p"/admin/quiz/#{@quiz.id}/scoring"}
        >
          Retting
        </.link>
        <!--<.link
          role="tab"
          class={["tab", @current_tab == :preview && "tab-active"]}
          navigate={~p"/admin/quiz/#{@quiz.id}/preview"}
        >
          Forhåndsvisning
        </.link>-->
        <.link
          role="tab"
          class={["tab", @current_tab == :submissions && "tab-active"]}
          navigate={~p"/admin/quiz/#{@quiz.id}/submissions"}
        >
          Besvarelser
        </.link>
        <.link
          role="tab"
          class={["tab", @current_tab == :leaderboard && "tab-active"]}
          navigate={~p"/admin/quiz/#{@quiz.id}/leaderboard"}
        >
          Leaderboard
        </.link>
      </div>
      {render_slot(@inner_block)}
    </.app>
    <script :type={Phoenix.LiveView.ColocatedHook} name=".MenuScroll">
      export default {
          mounted() {
            const active = this.el.getElementsByClassName('tab-active')[0]
            //TODO: scroll bare i tab-baren uten å scrolle hele siden
            //active?.scrollIntoView({inline: 'center', container: 'nearest'})
            }
          }
    </script>
    """
  end

  def no_header(assigns) do
    ~H"""
    <main class="px-4 py-20 sm:px-6 lg:px-8 bg-base-200">
      <div class="mx-auto max-w-2xl space-y-4">
        {render_slot(@inner_block)}
      </div>
    </main>

    <.flash_group flash={@flash} />
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-server-error #server-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Provides dark vs light theme toggle based on themes defined in app.css.

  See <head> in root.html.heex which applies the theme before page load.
  """
  def theme_toggle(assigns) do
    ~H"""
    <div class="card relative flex flex-row items-center border-2 border-base-300 bg-base-300 rounded-full">
      <div class="absolute w-1/3 h-full rounded-full border-1 border-base-200 bg-base-100 brightness-200 left-0 [[data-theme=light]_&]:left-1/3 [[data-theme=dark]_&]:left-2/3 transition-[left]" />

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="system"
      >
        <.icon name="hero-computer-desktop-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="light"
      >
        <.icon name="hero-sun-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="dark"
      >
        <.icon name="hero-moon-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>
    </div>
    """
  end
end
