defmodule AndaWeb.Router do
  use AndaWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {AndaWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
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
      live "/:id", Index, :index
    end

    scope "/quiz/:id/leaderboard", LeaderboardLive do
      live "/", Index, :index
    end

    scope "/admin", QuizLive do
      live "/", Index
      live "/quiz/:id", Edit, :index
      live "/quiz/:id/edit", Edit, :edit_quiz
      live "/quiz/:id/section/:section_id/question/new", Edit, :new_question
      live "/quiz/:id/section/:section_id/question/:question_id/edit", Edit, :edit_question
      live "/quiz/:id/section/new", Edit, :new_section
      live "/quiz/:id/section/:section_id/edit", Edit, :edit_section
      live "/quiz/:id/question/:question_id/score", Edit, :score_question
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
end
