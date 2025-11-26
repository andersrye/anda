defmodule Mac do
  alias AndaWeb.Endpoint

  defp mac(data), do: :crypto.macN(:hmac, :sha256, Endpoint.config(:secret_key_base), data, 8)

  defp verify_mac(data, mac) do
    if mac == mac(data) do
      {:ok, data}
    else
      {:error, :invalid_mac}
    end
  end

  def add_mac(string) do
    string <> "." <> Base.url_encode64(mac(string), padding: false)
  end

  def verify_added_mac(string) do
    [encoded_mac | rest] = String.split(string, ".") |> Enum.reverse()
    mac = Base.url_decode64!(encoded_mac, padding: false)
    payload = Enum.join(rest, ".")
    verify_mac(payload, mac)
  end

  def encode(payload) do
    mac = mac(payload)
    Base.url_encode64(<<1>> <> mac <> payload, padding: false)
  end

  def decode(string) do
    with {:ok, <<1, mac::binary-size(8), payload::binary>>} <-
           Base.url_decode64(string, padding: false),
         {:ok, payload} <- verify_mac(payload, mac) do
      {:ok, payload}
    else
      {:error, msg} -> {:error, msg}
      _ -> {:error, :unknown_error}
    end
  end
end
