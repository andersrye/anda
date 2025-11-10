defmodule AndaWeb.AnswerLive.LiveForm do
  import AndaWeb.CoreComponents
  use Phoenix.Component

  attr :id, :string, required: true
  attr :for, :any, required: true, doc: "the data structure for the form"
  slot :inner_block, required: true
  attr :class, :string, default: ""
  attr :eventname, :string, default: ""
  attr :target, :string, default: ""

  attr :rest, :global,
    include: ~w(autocomplete name rel action enctype method novalidate target multipart),
    doc: "the arbitrary HTML attributes to apply to the form tag"

  def live_form(assigns) do
    ~H"""
    <.form for={@for} id={@id} phx-hook=".LiveForm" class={@class} phx-target={@target} {@rest}>
      <div>
        {render_slot(@inner_block)}
      </div>
      <div class="indicators">
        <.loading class="loading-indicator hidden" />
        <.saved class="saved-indicator hidden" />
      </div>
      <button type="submit" class="hidden" disabled></button>
    </.form>
    <script :type={Phoenix.LiveView.ColocatedHook} name=".LiveForm">
      let eventHandler
      export default {
      mounted() {
        const fieldName = "form[text][]"
        const firstInput = this.el.querySelectorAll(`[name="${fieldName}"]`)[0]
        const loadingIndicator = this.el.getElementsByClassName("loading-indicator")[0]
        const savedIndicator = this.el.getElementsByClassName("saved-indicator")[0]
        const eventType = firstInput?.type === 'text' ? 'input' : 'change'
        let sendTimer, loadingTimer
        this.el?.addEventListener(eventType, e => {
          //console.log('change event', e)
          //console.log('change form', this.el)
          console.log('this.el.elements', this.el.elements)
          console.log('this.el.elements[fieldName]', this.el.elements[fieldName])
          const newValue = this.el.elements[fieldName].value
          console.log('change value', newValue)
          savedIndicator.classList.add('hidden')
          //firstInput.classList.remove('test-saved2')
          loadingTimer = setTimeout(() => {
          loadingIndicator.classList.remove('hidden')

          }, 1000)

          clearTimeout(sendTimer)
          sendTimer = setTimeout(()=> {
            this.pushEventTo(this.el.getAttribute('phx-target'), "live_form", {"value": newValue}, ({result}) => {
              clearTimeout(loadingTimer)
              loadingIndicator.classList.add('hidden')
                            if(result === 'ok') {
              savedIndicator.classList.remove('hidden')
              savedIndicator.classList.add('fade-out')
          //firstInput.classList.add('test-saved2')

              }

              console.log('reply', result)
            })
          }, 600)
        })
      }
      }
    </script>
    """
  end
end
