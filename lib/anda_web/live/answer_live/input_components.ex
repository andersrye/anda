defmodule AndaWeb.AnswerLive.InputComponents do
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
        prompt="Velg et svar"
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
        options={for a <- @options || [], do: {a, a}}
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
end
