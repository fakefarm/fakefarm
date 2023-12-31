defmodule Servy.Handler do
  @moduledoc "This is module wide documentation"

  alias Servy.Conv
  alias Servy.BearController

  @pages_page Path.expand("../../pages", __DIR__)

  # import will import other modules.
  # running a file by itself will not load them
  # but running as a mix project (iex -S mix)
  # will load all necessary modules.

  import Servy.Plugins, only: [rewrite_path: 1, log: 1, track: 1]

  import Servy.Parser, only: [parse: 1]
  import Servy.File, only: [handle_file: 2]

  def handle(request) do
    request
    |> parse
    |> rewrite_path
    |> log
    |> route
    |> track
    |> format_response
  end

  def emojify(%Conv{status: 200 } = conv) do
    rb = "👋👋👋\n#{conv.resp_body}\n🤙🤙🤙"
    %{ conv | resp_body: rb }
  end

  def emojify(%Conv{} = conv), do: conv

  def route(%Conv{method: "GET", path: "/wildthings"} = conv) do
    %{ conv | resp_body: "Bears, Lions, Tigers", status: 200 }
  end

  def route(%Conv{method: "GET", path: "/bears"} = conv) do
    BearController.index(conv)
    # %{ conv | resp_body: "Literacy is the foundation", status: 200 }
  end

  def route(%Conv{method: "POST", path: "/bears"} = conv) do
    BearController.create(conv, conv.params)
  end

  def route(%Conv{method: "GET", path: "/bears/new"} = conv) do
    @pages_page
    |> Path.join("form.html")
    |> File.read
    |> handle_file(%Conv{} = conv)
  end

  def route(%Conv{method: "GET", path: "/bears/" <> id} = conv) do
    params = Map.put(conv.params, "id", id)
    BearController.show(conv, params)
  end

  def route(%Conv{method: "DELETE", path: "/bears/" <> id} = conv) do
    # _dw figure out this error message. How to read it?
    params = Map.put(conv.params, "id", id)
    BearController.delete(conv, params)
  end

  def route(%Conv{method: "GET", path: "/about"} = conv) do
    @pages_page
    |> Path.join("about.html")
    |> File.read
    |> handle_file(%Conv{} = conv)
  end

  # def route(%Conv{method: "GET", path: "/pages" <> page } = conv) do
  def route(%Conv{method: "GET", path: "/pages" <> page } = conv) do
    @pages_page
    |> Path.join("#{page}.html")
    |> File.read
    |> handle_file(%Conv{} = conv)
  end

  # route function using case statement approach instead of a multi-clause approach above.

  # def route(%Conv{method: "GET", path: "/about"} = conv) do
  #   file =
  #     Path.expand("../../pages/", __DIR__)
  #     |> Path.join("about.html")

      # case File.read(file) do
      #   {:ok, contents } ->
      #     %{ conv | resp_body: contents, status: 200 }
      #   {:error, :enoent } ->
      #     %{ conv | resp_body: "File Not found", status: 404 }
      #   {:error, reason } ->
      #     %{ conv | resp_body: reason, status: 500 }
      # end
  # end

    def route(%Conv{method: "GET", path: "/genesis" <> chapter} = conv) do
      %{ conv | status: 200, resp_body: "Genesis #{chapter}, a great place to begin."}
    end

    def route(%Conv{method: "DELETE", path: "/genesis" <> chapter} = conv) do
      %{ conv | status: 403, resp_body: "Genesis #{chapter}, is your loss"}
    end

# catch all - whatever the path is, is not intended,
# and so we assign it to variable from conv.
  def route(%Conv{ path: path } = conv) do
    %{ conv | resp_body: "No #{path} here!", status: 404 }
  end

  def format_response(%Conv{} = conv) do
    """
    HTTP/1.1 #{Conv.full_status(conv)}\r
    Content-Type: text/html\r
    Content-Length: #{String.length(conv.resp_body)}\r
    \r
    #{conv.resp_body}
    """
  end
end
