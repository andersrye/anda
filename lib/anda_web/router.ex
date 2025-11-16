defmodule AndaWeb.Router do
  use AndaWeb, :router

  import AndaWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {AndaWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_scope_for_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :submission do
    plug SubmissionPlug
  end

  scope "/", AndaWeb do
    pipe_through :browser

    get "/", PageController, :home

    # live "/quiz/new", QuizLive.Index, :new

    scope "/quiz", AnswerLive do
      pipe_through :submission
      live "/:quiz_id", Index, :edit
    end

    scope "/quiz/:quiz_id/leaderboard", LeaderboardLive do
      live "/", Index, :index
    end

    scope "/admin" do
      pipe_through :require_authenticated_user

      live_session :quizmaster,
        on_mount: [{AndaWeb.UserAuth, :require_authenticated}] do
        live "/", QuizLive.Index
        scope "/quiz/:quiz_id" do
          live "/", QuizLive.Edit, :index
          live "/edit", QuizLive.Edit, :edit_quiz
          live "/question/new", QuizLive.Edit, :new_question
          live "/question/:question_id/edit", QuizLive.Edit, :edit_question
          live "/question/:question_id/delete", QuizLive.Edit, :delete_question
          live "/question/:question_id/score", QuizLive.Edit, :score_question
          live "/section/new", QuizLive.Edit, :new_section
          live "/section/:section_id/edit", QuizLive.Edit, :edit_section
          live "/leaderboard", LeaderboardLive.Index, :index
          live "/submissions", SubmissionsLive.Index, :index
          live "/submissions/:submission_id", AnswerLive.Index, :view
          live "/submissions/:submission_id/add-tag", SubmissionsLive.Index, :add_tag
          live "/preview", AnswerLive.Index, :preview

        end
      end
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", AndaWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:anda, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: AndaWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", AndaWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{AndaWeb.UserAuth, :require_authenticated}] do
      live "/users/settings", UserLive.Settings, :edit
      live "/users/settings/confirm-email/:token", UserLive.Settings, :confirm_email
    end

    post "/users/update-password", UserSessionController, :update_password
  end

  scope "/", AndaWeb do
    pipe_through [:browser]

    live_session :current_user,
      on_mount: [{AndaWeb.UserAuth, :mount_current_scope}] do
      live "/users/register", UserLive.Registration, :new
      live "/users/log-in", UserLive.Login, :new
      live "/users/log-in/:token", UserLive.Confirmation, :new
    end

    post "/users/log-in", UserSessionController, :create
    delete "/users/log-out", UserSessionController, :delete
  end
end
