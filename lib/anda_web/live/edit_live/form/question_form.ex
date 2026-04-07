defmodule AndaWeb.EditLive.Form.QuestionForm do
  use AndaWeb, :live_component

  alias Anda.Contest
  alias Ecto.Changeset
  alias Anda.Contest.Question

  @impl true
  def render(assigns) do
    assigns = assign(assigns, selected_file: Enum.at(assigns.uploads.file.entries, 0))

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
          <legend class="label mb-1">Bilde/Lyd/Video (valgfritt)</legend>
          <figure :if={@selected_file}>
            <.media_preview
              field={@form[:aspect_ratio]}
              entry={@selected_file}
              class="max-h-50 mb-3 mt-1"
            />
          </figure>
          <figure :if={!@selected_file && @question.media_url && !@remove_file}>
            <.simple_media_view
              id={"media-preview-#{@question.id}"}
              src={@question.media_url}
              type={@question.media_type}
              aspect_ratio={@question.media_aspect_ratio}
            />
          </figure>
          <p :for={err <- upload_errors(@uploads.file)} class="alert alert-danger">
            {error_to_string(err)}
          </p>
          <div class="mb-8 flex gap-2">
            <.live_file_input upload={@uploads.file} class="file-input" />
            <.button
              :if={@selected_file || (@question.media_url && !@remove_file)}
              type="button"
              class="btn btn-soft"
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
        <.input field={@form[:points]} type="number" label="Poeng (valgfritt)" />
        <div>
          <.button phx-disable-with="Lagrer...">Lagre</.button>
        </div>
      </.form>
    </div>
    """
  end

  attr :id, :string, default: nil

  attr :entry, Phoenix.LiveView.UploadEntry,
    required: true,
    doc: "The `Phoenix.LiveView.UploadEntry` struct"

  attr :field, Phoenix.HTML.FormField
  attr :rest, :global

  def media_preview(assigns) do
    ~H"""
    <div
      id={@id || "phx-preview-#{@entry.ref}"}
      data-upload-ref={@entry.upload_ref}
      data-entry-ref={@entry.ref}
      data-type={@entry.client_type}
      phx-hook=".LiveMediaPreview"
      phx-update="ignore"
      {@rest}
    >
      <.input field={@field} type="hidden" />
      <img
        :if={String.starts_with?(@entry.client_type, "image")}
        class="max-w-[inherit] max-h-[inherit]"
      />
      <video
        :if={String.starts_with?(@entry.client_type, "video")}
        controls
        controlslist="nodownload nofullscreen noremoteplayback"
        class="max-w-[inherit] max-h-[inherit]"
      >
        <source />
      </video>
      <audio
        :if={String.starts_with?(@entry.client_type, "audio")}
        controls
        controlslist="nodownload nofullscreen noremoteplayback"
        class="max-w-[inherit] max-h-[inherit]"
      >
        <source />
      </audio>
    </div>

    <script :type={Phoenix.LiveView.ColocatedHook} name=".LiveMediaPreview">
      export default {
      mounted() {
          const ref = this.el.getAttribute("data-entry-ref")
          const uploadRef = this.el.getAttribute("data-upload-ref")
          const type = this.el.getAttribute("data-type")
          const fileInput = document.getElementById(uploadRef)
          const arInput = this.el.getElementsByTagName('input')[0]
          const file = Array.from(fileInput.files).find(f => f._phxRef == ref)
          this.url = URL.createObjectURL(file)
          if(type.startsWith("image")) {
            const img = this.el.getElementsByTagName('img')[0]
            img.src = this.url
            img.onload = (e) => {
              const aspectRatio = e.target.width / e.target.height
              arInput.value = aspectRatio.toString()
              arInput.dispatchEvent(new Event("input", {bubbles: true}))
          }
          } else if(type.startsWith("video")) {
            const video = this.el.getElementsByTagName('video')[0]
            const source = this.el.getElementsByTagName('source')[0]
            source.src = this.url
            video.onloadeddata = (e) => {
              const aspectRatio = e.target.videoWidth / e.target.videoHeight
              arInput.value = aspectRatio.toString()
              arInput.dispatchEvent(new Event("input", {bubbles: true}))
          }
          } else if(type.startsWith("audio")) {
            const source = this.el.getElementsByTagName('source')[0]
            source.src = this.url
          }
        },
        destroyed() {
          URL.revokeObjectURL(this.url);
        }
      }
    </script>
    """
  end

  defp form_types() do
    %{
      text: :string,
      alternatives: :string,
      type: :string,
      num_answers: :integer,
      points: :integer,
      aspect_ratio: :float
    }
  end

  defp to_params(question) do
    question
    |> Map.take([:text, :alternatives, :type, :num_answers, :aspect_ratio, :points])
    |> Map.update(:alternatives, [], fn val ->
      if !is_nil(val), do: Enum.join(val, "\n"), else: nil
    end)
    |> then(&Changeset.change({&1, form_types()}))
  end

  defp changeset(changeset, params) do
    changeset
    |> Changeset.cast(params, [:text, :alternatives, :type, :num_answers, :aspect_ratio, :points])
    |> Changeset.validate_required([:text])
  end

  @impl true
  def update(assigns, socket) do
    question =
      if assigns.action == :edit do
        Contest.get_question!(assigns.question_id, assigns.current_scope)
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
       max_file_size: 8_000_000
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
          |> Map.put(:media_aspect_ratio, nil)
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
          |> Map.put(:media_aspect_ratio, question_params.aspect_ratio)
        else
          q
        end
      end)

    save_question(socket, socket.assigns.action, question_params)
  end

  defp save_question(socket, :edit, question_params) do
    case Contest.update_question(socket.assigns.question, question_params) do
      {:ok, question} ->
        notify_parent({:updated, question})

        {:noreply,
         socket
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_question(socket, :new, question_params) do
    question =
      question_params
      |> Map.put(:section_id, socket.assigns.section_id)

    case Contest.create_question(question, socket.assigns.current_scope) do
      {:ok, question} ->
        notify_parent({:created, question})

        {:noreply,
         socket
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  defp error_to_string(:too_large), do: "Too large"
  defp error_to_string(:too_many_files), do: "You have selected too many files"
  defp error_to_string(:not_accepted), do: "You have selected an unacceptable file type"
end
