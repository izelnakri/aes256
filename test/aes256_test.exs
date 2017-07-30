defmodule AES256Test do
  use ExUnit.Case
  doctest AES256

  test "can encrypt and decrypt passwords correctly for default options" do
    plaintexts = [
      "sample plain text", "now you can encrypt things in elixir", "another plain text",
      "keep reading the source code", "also its encouraged to suggest improvements"
    ]

    passwords = ["sample", "password", "whatever", "123456", "cantguess"]

    plaintexts |> Enum.each(fn(plaintext) ->
      Enum.each(passwords, fn(password) ->
        [iv: iv, ciphertext: ciphertext] = AES256.encrypt(plaintext, password)

        assert AES256.decrypt(ciphertext, password, iv) == plaintext

        assert AES256.decrypt(ciphertext, "", iv) != plaintext
        assert AES256.decrypt(ciphertext, "abcdefgh", iv) != plaintext

        another_iv = :crypto.strong_rand_bytes(16)
        assert AES256.decrypt(ciphertext, password, another_iv) != plaintext

        key = :crypto.hash(:sha256, password)

        File.write("tmp/iv", iv)
        File.write("tmp/pass", key)

        openssl_response =
          "echo \"#{ciphertext}\" | openssl enc -d -aes-256-cbc -iv $(hexdump -v -e '/1 \"%02X\"' < \"tmp/iv\") -K $(hexdump -v -e '/1 \"%02X\"' < \"tmp/pass\") -base64"
          |> String.to_charlist
          |> :os.cmd
          |> to_string

        assert openssl_response == plaintext
      end)
    end)
  end

  # TODO: write another one for with mode explicit

  # NOTE: to ExUnit expects function

  # NOTE: Base64 option
end
