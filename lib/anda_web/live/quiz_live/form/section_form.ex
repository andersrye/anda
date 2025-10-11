defmodule AndaWeb.QuizLive.Form.SectionForm do
alias Anda.Contest.Section
  use AndaWeb, :live_component

  alias Anda.Contest

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
      Seksjon
      </.header>

      <.simple_form
        for={@form}
        id="section-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:title]} type="text" label="Title" />
        <.input field={@form[:description]} type="text" label="Description" />
        <:actions>
          <.button phx-disable-with="Saving...">Lagre</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    section = if assigns.action == :edit_section do
      Contest.get_section!(assigns.section_id)
    else
      %Section{quiz_id: assigns.quiz.id}
    end

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:section, section)
     |> assign_new(:form, fn ->
       to_form(Contest.change_section(section))
     end)
    }
  end

  @impl true
  def handle_event("validate", %{"section" => section_params}, socket) do
    changeset = Contest.change_section(socket.assigns.section, section_params)
    form = to_form(changeset, action: :validate)
    {:noreply, assign(socket, form: form)}
  end

  def handle_event("save", %{"section" => section_params}, socket) do
    save_section(socket, socket.assigns.action, section_params)
  end

  defp save_section(socket, :edit_section, section_params) do
    case Contest.update_section(socket.assigns.section, section_params) do
      {:ok, section} ->
        notify_parent({:saved, section})

        {:noreply,
         socket
         |> put_flash(:info, "Section updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_section(socket, :new_section, section_params) do
    section = Map.put(section_params, "quiz_id", socket.assigns.quiz.id)
    case Contest.create_section(section) do
      {:ok, section} ->
        notify_parent({:saved, section})

        {:noreply,
         socket
         |> put_flash(:info, "Section created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
