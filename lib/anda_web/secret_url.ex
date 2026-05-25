defmodule AndaWeb.SecretUrl do
  def secret_url(secret) do
    with {:ok, bytes} <- Ecto.UUID.dump(secret) do
      Mac.encode(<<1>> <> bytes)
    else
      :error ->
        {:ok, bytes} = Base.decode64(secret)
        Mac.encode(<<2>> <> bytes)
    end
  end

  def verify_secret_url(string) do
    case Mac.decode(string) do
      {:ok, <<1, uuid_bytes::binary>>} -> Ecto.UUID.cast(uuid_bytes)
      {:ok, <<2, hash_bytes::binary>>} -> {:ok, Base.encode64(hash_bytes)}
    end
  end
end
