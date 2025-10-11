defmodule AndaWeb.QuizLive.Form.QuestionForm do
  use AndaWeb, :live_component

  alias Anda.Contest
  alias Ecto.Changeset

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Spørsmål</:subtitle>
      </.header>
      <section phx-drop-target={@uploads.avatar.ref} class="bg-red-400 min-h-24">
        <%!-- render each avatar entry --%>
        <article :for={entry <- @uploads.avatar.entries} class="upload-entry">
          <figure>
            <.live_img_preview entry={entry} />
            <figcaption>{entry.client_name}</figcaption>
          </figure>

          <%!-- entry.progress will update automatically for in-flight entries --%>
          <progress :if={entry.progress < 100 && entry.progress > 0} value={entry.progress} max="100">
            {entry.progress}%
          </progress>

          <%!-- a regular click event whose handler will invoke Phoenix.LiveView.cancel_upload/3 --%>
          <button
            type="button"
            phx-click="cancel-upload"
            phx-value-ref={entry.ref}
            aria-label="cancel"
          >
            &times;
          </button>

          <%!-- Phoenix.Component.upload_errors/2 returns a list of error atoms --%>
          <p :for={err <- upload_errors(@uploads.avatar, entry)} class="alert alert-danger">
            {error_to_string(err)}
          </p>
        </article>

        <%!-- Phoenix.Component.upload_errors/1 returns a list of error atoms --%>
        <p :for={err <- upload_errors(@uploads.avatar)} class="alert alert-danger">
          {error_to_string(err)}
        </p>
      </section>
      <.simple_form
        for={@form}
        id="section-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:question]} type="text" label="Spørsmål" />
        <.input field={@form[:alternatives]} type="textarea" label="Alternativer" />
        <.live_file_input upload={@uploads.avatar} class="file-input" />
        <:actions>
          <.button phx-disable-with="Saving...">Save</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  defp form_types() do
    %{
      question: :string,
      alternatives: :string
    }
  end

  defp to_params(question) do
    question
    |> Map.take([:question, :alternatives])
    |> Map.update(:alternatives, [], fn val ->
      if !is_nil(val), do: Enum.join(val, "\n"), else: nil
    end)
    |> then(&Changeset.change({&1, form_types()}))
  end

  defp changeset(changeset, params) do
    changeset
    |> Changeset.cast(params, [:question, :alternatives])
    |> Changeset.validate_required([:question])

    # |> Changeset.apply_action(:validate)
  end

  @impl true
  def update(assigns, socket) do
    question =
      Map.get(assigns, :question)

    form_params = to_params(question)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:question, question)
     |> assign(:question_form_data, form_params)
     |> assign_new(:form, fn -> to_form(form_params, as: "question") end)
     |> assign(:uploaded_files, [])
     |> allow_upload(:avatar,
       accept: ~w(.jpg .jpeg .png .mp4 .mp3),
       max_entries: 1,
       external: &presign_upload/2
     )}
  end

  defp presign_upload(entry, socket) do
    uploads = socket.assigns.uploads

    dbg(entry)
    bucket = "anda-test"
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
    {:noreply, cancel_upload(socket, :avatar, ref)}
  end

  def handle_event("save", %{"question" => question_params}, socket) do
    uploaded_files =
      consume_uploaded_entries(socket, :avatar, fn %{url: url, key: key},
                                                   %{client_type: client_type} ->
        {:ok, {url <> "/" <> key, client_type}}
      end)

    dbg(uploaded_files)

    {:ok, question_params} =
      changeset(socket.assigns.question_form_data, question_params)
      |> Changeset.apply_action(:save)

    question_params =
      question_params
      |> Map.update(:alternatives, nil, fn val ->
        if !is_nil(val), do: String.split(val, "\n"), else: nil
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
      dbg(question_params)

    save_question(socket, socket.assigns.edit_action, question_params)
  end

  defp save_question(socket, :edit_question, question_params) do
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

  defp save_question(socket, :new_question, question_params) do
    question =
      question_params
      |> Map.put(:section_id, socket.assigns.section.id)
      |> Map.put(:num_answers, 1)

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
