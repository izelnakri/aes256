defmodule AES256 do
  @moduledoc """
  Documentation for Aes256.
  """

  def encrypt(plaintext, password, iv \\ :crypto.strong_rand_bytes(16), options \\ [mode: :cbc, base64: true]) do
    key = :crypto.hash(:sha256, password)
    result = :crypto.block_encrypt(:aes_cbc256, key, iv, pkcs7_pad(plaintext))

    ciphertext = if options[:base64], do: Base.encode64(result), else: result

    [iv: iv, ciphertext: ciphertext]
  end

  def encrypt!(plaintext, password, iv \\ :crypto.strong_rand_bytes(16), options \\ [mode: :cbc, base64: true]) do
    key = :crypto.hash(:sha256, password)
    ciphertext = :crypto.block_encrypt(:aes_cbc256, key, iv, pkcs7_pad(plaintext))

    result = iv <> ciphertext

    if options[:base64], do: Base.encode64(result), else: result
  end

  def decrypt(ciphertext, password, iv, options \\ [mode: :cbc, base64: true])
  def decrypt(ciphertext, password, nil, options) do
    raise "IV(initialization vector) is required to decrypt your ciphertext"
  end
  def decrypt(ciphertext, password, iv, options) do
    key = :crypto.hash(:sha256, password)
    target = if options[:base64], do: Base.decode64!(ciphertext), else: ciphertext

    padded = :crypto.block_decrypt(:aes_cbc256, key, iv, target)

    case pkcs7_unpad(padded) do
      {:ok, plaintext} -> plaintext
      result -> result
    end
  end

  def decrypt!(ciphertext_with_iv, password, options \\ [mode: :cbc, base64: true]) do
    key = :crypto.hash(:sha256, password)

    target = if options[:base64], do: Base.decode64!(ciphertext_with_iv), else: ciphertext_with_iv

    {iv, target_ciphertext} = String.split_at(target, 16)

    padded = :crypto.block_decrypt(:aes_cbc256, key, iv, target_ciphertext)
    {:ok, plaintext} = pkcs7_unpad(padded)

    plaintext
  end

  def create_hmac(password, ciphertext) do
    key = :crypto.hash(:sha256, password)
    :crypto.hmac(:sha256, key, ciphertext)
  end

  # Pads a message using the PKCS #7 cryptographic message syntax.
  #
  # See: https://tools.ietf.org/html/rfc2315
  # See: `pkcs7_unpad/1`
  defp pkcs7_pad(message) do
    bytes_remaining = rem(byte_size(message), 16)
    padding_size = 16 - bytes_remaining
    message <> :binary.copy(<<padding_size>>, padding_size)
  end

  # Unpads a message using the PKCS #7 cryptographic message syntax.
  #
  # See: https://tools.ietf.org/html/rfc2315
  # See: `pkcs7_pad/1`
  defp pkcs7_unpad(<<>>), do: :error
  defp pkcs7_unpad(message) do
    padding_size = :binary.last(message)
    if padding_size <= 16 do
      message_size = byte_size(message)
      if binary_part(message, message_size, -padding_size) === :binary.copy(<<padding_size>>, padding_size) do
        {:ok, binary_part(message, 0, message_size - padding_size)}
      else
        :error
      end
    else
      :error
    end
  end
end
