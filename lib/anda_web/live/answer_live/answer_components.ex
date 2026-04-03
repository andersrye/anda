defmodule AndaWeb.AnswerLive.AnswerComponents do
  use Phoenix.Component
  use AndaWeb, :html

  attr :field, Phoenix.HTML.FormField
  attr :id, :string
  attr :class, :string, default: ""

  attr :rest, :global,
    include: ~w(accept autocomplete capture cols disabled form list max maxlength min minlength
                multiple pattern placeholder readonly required rows size step id class)

  @spec text_input(map()) :: Phoenix.LiveView.Rendered.t()
  def text_input(assigns) do
    ~H"""
    <div id={"#{@id}-container"} phx-hook=".LiveTextInput">
      <.input
        id={@id}
        class={@class}
        type="text"
        field={@field}
        {@rest}
      />
      <.saved class="saved hidden" />
    </div>
    <script :type={Phoenix.LiveView.ColocatedHook} name=".LiveTextInput">
      export default {
        mounted() {
          const input = this.el.getElementsByTagName('input')[0]
          //const saved = this.el.getElementsByClassName('saved')[0]
          const target = input.attributes["phx-target"].value
          let timer
          input.addEventListener("input", e => {
            input.classList.remove('input-success')
            //saved.classList.add('hidden')
            clearTimeout(timer)
            timer = setTimeout(()=> {
              this.pushEventTo(target, "submit", {"answer": {"text": input.value}}, (reply) => {
                if(reply?.success) {
                input.classList.add('input-success')
                //saved.classList.remove('hidden')
                }
              })
            }, 600)
          })
        }
      }
    </script>
    """
  end

  attr :field, Phoenix.HTML.FormField
  attr :id, :string
  attr :class, :string, default: ""
  attr :options, :list
  attr :prompt, :string

  attr :rest, :global,
    include: ~w(accept autocomplete capture cols disabled form list max maxlength min minlength
                multiple pattern placeholder readonly required rows size step id class)

  def select_input(assigns) do
    ~H"""
    <div id={"#{@id}-container"} phx-hook=".LiveSelectInput">
      <.input
        id={"input-#{@id}"}
        field={@field}
        class={@class}
        type="select"
        options={for a <- @options || [], do: {a, a}}
        prompt={@prompt}
        {@rest}
      />
      <.saved class="saved hidden" />
    </div>
    <script :type={Phoenix.LiveView.ColocatedHook} name=".LiveSelectInput">
      export default {
        mounted() {
          const input = this.el.getElementsByTagName('select')[0]
          //const saved = this.el.getElementsByClassName('saved')[0]
          const target = input.attributes["phx-target"].value
          input.addEventListener("change", e => {
            input.classList.remove('input-success')
            //saved.classList.add('hidden')
              this.pushEventTo(target, "submit", {"answer": {"text": input.value}}, (reply) => {
                if(reply?.success) {
                input.classList.add('input-success')
                //saved.classList.remove('hidden')
                }
              })
          })
        }
      }
    </script>
    """
  end

  attr :field, Phoenix.HTML.FormField
  attr :id, :string
  attr :class, :string, default: ""
  attr :options, :list

  attr :rest, :global,
    include: ~w(accept autocomplete capture cols disabled form list max maxlength min minlength
                multiple pattern placeholder readonly required rows size step id class)

  def radio_input(assigns) do
    ~H"""
    <div id={"#{@id}-container"} phx-hook=".LiveRadioInput">
      <.input
        id={"input-#{@id}"}
        field={@field}
        type="radiogroup"
        options={for a <- @options || [], do: %{label: a, value: a}}
        {@rest}
      />
      <.saved class="saved hidden" />
    </div>
    <script :type={Phoenix.LiveView.ColocatedHook} name=".LiveRadioInput">
      export default {
        mounted() {
          const inputs = this.el.querySelectorAll('input[type=radio]')
          //const saved = this.el.getElementsByClassName('saved')[0]
          const target = inputs[0].attributes["phx-target"].value
          for(const input of inputs) {
            input.addEventListener("change", e => {
            for(const input of inputs) {
              input.classList.remove('input-success')
            }
            //saved.classList.add('hidden')
              this.pushEventTo(target, "submit", {"answer": {"text": input.value}}, (reply) => {
                if(reply?.success) {
                input.classList.add('input-success')
                //saved.classList.remove('hidden')
                }
              })
          })
          }

        }
      }
    </script>
    """
  end

  attr :field, Phoenix.HTML.FormField
  attr :id, :string
  attr :class, :string, default: ""

  attr :rest, :global,
    include: ~w(accept autocomplete capture cols disabled form list max maxlength min minlength
                multiple pattern placeholder readonly required rows size step id class)

  @spec name_input(map()) :: Phoenix.LiveView.Rendered.t()
  def name_input(assigns) do
    ~H"""
    <div id={"#{@id}-container"} phx-hook=".LiveNameInput">
      <.input
        id={@id}
        class={@class}
        label="Navn"
        placeholder="Skriv inn navnet ditt her"
        type="text"
        field={@field}
        {@rest}
      />
      <.saved class="saved hidden" />
    </div>
    <script :type={Phoenix.LiveView.ColocatedHook} name=".LiveNameInput">
      export default {
        mounted() {
          const input = this.el.getElementsByTagName('input')[0]
          //const saved = this.el.getElementsByClassName('saved')[0]
          let timer
          input.addEventListener("input", e => {
            input.classList.remove('input-success')
            //saved.classList.add('hidden')
            clearTimeout(timer)
            timer = setTimeout(()=> {
              this.pushEvent("change_name", {"name": input.value}, (reply) => {
                if(reply?.success) {
                  input.classList.add('input-success')
                //saved.classList.remove('hidden')
                }
              })
            }, 600)
          })
        }
      }
    </script>
    """
  end

  def section_menu(assigns) do
    ~H"""
    <details id="section-menu" class="dropdown dropdown-end" phx-hook=".SectionMenu">
      <summary class="btn m-1 btn-square btn-outline bg-base-200">
        <.icon name="hero-numbered-list" />
      </summary>
      <div class="dropdown-content  bg-base-100 rounded-box z-1 w-52 p-2 shadow-sm z-100 max-h-[80vh] overflow-auto">
        <p class="text-sm px-5 pt-3 font-bold">Gå til...</p>
        <ul class="menu w-full">
          <li :for={{section, _} <- @sections}>
            <.link href="" data-section={"section_#{section.id}"}>{section.title}</.link>
          </li>
        </ul>
      </div>
    </details>
    <script :type={Phoenix.LiveView.ColocatedHook} name=".SectionMenu">
      export default {
        mounted() {
          const details = this.el
          const links = this.el.getElementsByTagName('a')
          for(const link of links) {
            link.addEventListener('click', e => {
              e.preventDefault()
              const section = e.target.getAttribute("data-section")
              const el = document.getElementById(section)
              el?.scrollIntoView(true)
              details.open=false
            })
          }
        }
      }
    </script>
    """
  end

  attr :score, :integer

  def score(assigns) do
    ~H"""
    <div class="font-mono">
      <div
        :if={@score != nil && @score > 0}
        class="text-green-700 outline-green-700 outline-solid outline-2 rounded-full p-2 w-8 h-8 flex justify-center items-center -font-semibold"
      >
        {@score}p
      </div>
      <div :if={@score != nil && @score == 0}>
        <.icon name="hero-x-mark" class="w-8 h-8 p-2 bg-red-700" />
      </div>
    </div>
    """
  end
end
