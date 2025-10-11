defmodule AndaWeb.PageController do
  use AndaWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
