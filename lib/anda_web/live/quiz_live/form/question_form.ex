defmodule AndaWeb.QuizLive.Form.QuestionForm do
  use AndaWeb, :live_component

  alias Anda.Contest
  alias Ecto.Changeset
  alias Anda.Contest.Question

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        Spørsmål
      </.header>

      <.form
        for={@form}
        id="section-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:text]} type="textarea" label="Spørsmål" />

        <fieldset class="fieldset">
          <legend class="label mb-1">Bilde (valgfritt)</legend>
          <figure :if={Enum.count(@uploads.file.entries) == 1}>
            <.live_img_preview entry={Enum.at(@uploads.file.entries, 0)} />
          </figure>
          <figure :if={Enum.count(@uploads.file.entries) == 0 && @question.media_url && !@remove_file}>
            <img src={@question.media_url} />
          </figure>
          <p :for={err <- upload_errors(@uploads.file)} class="alert alert-danger">
            {error_to_string(err)}
          </p>
          <div class="mb-8 flex gap-2">
            <.live_file_input upload={@uploads.file} class="file-input" />
            <.button
            :if={Enum.count(@uploads.file.entries) == 1 || (@question.media_url && !@remove_file)}
            type="button"
            phx-click="remove-file"
            phx-target={@myself}
            aria-label="Fjern fil"
          >
            <.icon name="hero-trash" /> Fjern fil
          </.button>
          </div>
        </fieldset>
        <.input
          field={@form[:type]}
          type="select"
          label="Svarformat"
          options={[
            Fritekst: "text",
            Alternativer: "alternatives",
            Tall: "number",
            Fotballresultat: "football-score"
          ]}
        />

        <.input
          :if={@form[:type].value == "alternatives"}
          field={@form[:alternatives]}
          type="textarea"
          label="Alternativer"
        />

        <.input field={@form[:num_answers]} type="number" label="Antall svar" />
        <div>
          <.button phx-disable-with="Saving...">Save</.button>
        </div>
      </.form>
    </div>
    """
  end

  defp form_types() do
    %{
      text: :string,
      alternatives: :string,
      type: :string,
      num_answers: :integer
    }
  end

  defp to_params(question) do
    question
    |> Map.take([:text, :alternatives, :type, :num_answers])
    |> Map.update(:alternatives, [], fn val ->
      if !is_nil(val), do: Enum.join(val, "\n"), else: nil
    end)
    |> then(&Changeset.change({&1, form_types()}))
  end

  defp changeset(changeset, params) do
    changeset
    |> Changeset.cast(params, [:text, :alternatives, :type, :num_answers])
    |> Changeset.validate_required([:text])
  end

  @impl true
  def update(assigns, socket) do
    question =
      if assigns.action == :edit do
        Contest.get_question!(assigns.question_id)
      else
        %Question{
          section_id: assigns.section_id,
          num_answers: 1,
          alternatives: []
        }
      end

    form_params = to_params(question)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:question, question)
     |> assign(:question_form_data, form_params)
     |> assign_new(:form, fn -> to_form(form_params, as: "question") end)
     |> assign(:uploaded_files, [])
     |> assign(:remove_file, false)
     |> allow_upload(:file,
       accept: ~w(.jpg .jpeg .png .mp4 .mp3),
       max_entries: 1,
       external: &presign_upload/2,
       type: "text"
     )}
  end

  defp presign_upload(entry, socket) do
    uploads = socket.assigns.uploads
    # "anda-dev"
    bucket = Application.get_env(:anda, :aws)[:bucket_name]
    key = "public/#{Ecto.UUID.generate()}#{Path.extname(entry.client_name)}"

    config = %{
      region: Application.fetch_env!(:anda, :aws)[:aws_region],
      access_key_id: Application.fetch_env!(:anda, :aws)[:aws_access_key_id],
      secret_access_key: Application.fetch_env!(:anda, :aws)[:aws_secret_access_key]
    }

    bucket_url = "https://#{bucket}.s3.#{config.region}.scw.cloud"

    {:ok, fields} =
      SimpleS3Upload.sign_form_upload(config, bucket,
        key: key,
        content_type: entry.client_type,
        max_file_size: uploads[entry.upload_config].max_file_size,
        expires_in: :timer.hours(1)
      )

    meta = %{uploader: "S3", key: key, url: bucket_url, fields: fields}
    {:ok, meta, socket}
  end

  @impl true
  def handle_event("validate", %{"question" => params}, socket) do
    changeset = changeset(socket.assigns.question_form_data, params)
    form = to_form(changeset, action: :validate, as: "question")
    {:noreply, assign(socket, form: form)}
  end

  @impl true
  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :file, ref)}
  end

  def handle_event("remove-file", _, socket) do
    uploaded_file = Enum.at(socket.assigns.uploads.file.entries, 0)

    socket =
      if uploaded_file do
        cancel_upload(socket, :file, uploaded_file.ref)
      else
        socket
      end

    {:noreply, socket |> assign(:remove_file, true)}
  end

  def handle_event("save", %{"question" => question_params}, socket) do
    uploaded_files =
      consume_uploaded_entries(socket, :file, fn %{url: url, key: key},
                                                 %{client_type: client_type} ->
        {:ok, {url <> "/" <> key, client_type}}
      end)

    {:ok, question_params} =
      changeset(socket.assigns.question_form_data, question_params)
      |> Changeset.apply_action(:save)

    question_params =
      question_params
      |> Map.update(:alternatives, nil, fn val ->
        if !is_nil(val), do: String.split(val, "\n") |> Enum.map(&String.trim/1), else: nil
      end)
      |> then(fn q ->
        if(socket.assigns.remove_file) do
          q
          |> Map.put(:media_url, nil)
          |> Map.put(:media_type, nil)
        else
          q
        end
      end)
      |> then(fn q ->
        if(Enum.count(uploaded_files) == 1) do
          {media_url, media_type} = Enum.at(uploaded_files, 0)

          q
          |> Map.put(:media_url, media_url)
          |> Map.put(:media_type, media_type)
        else
          q
        end
      end)

    # dbg(question_params)

    save_question(socket, socket.assigns.action, question_params)
  end

  defp save_question(socket, :edit, question_params) do
    case Contest.update_question(socket.assigns.question, question_params) do
      {:ok, question} ->
        notify_parent({:saved, question})
        socket.assigns.on_saved.(question)

        {:noreply,
         socket
         |> put_flash(:info, "Question updated successfully")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_question(socket, :new, question_params) do
    question =
      question_params
      |> Map.put(:section_id, socket.assigns.section_id)

    case Contest.create_question(question) do
      {:ok, question} ->
        notify_parent({:saved, question})
        socket.assigns.on_saved.(question)

        {:noreply,
         socket
         |> put_flash(:info, "Question created successfully")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  defp error_to_string(:too_large), do: "Too large"
  defp error_to_string(:too_many_files), do: "You have selected too many files"
  defp error_to_string(:not_accepted), do: "You have selected an unacceptable file type"
end
