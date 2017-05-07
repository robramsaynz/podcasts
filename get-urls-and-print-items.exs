#!/usr/bin/env elixir
#
# $ ./get-list.exs | pbcopy
#


defmodule RinseFMRSSFeed do
  def save_links(links) do
    !File.write("./ex_links.dat", Enum.join(links, "\n"));
    !File.write("./ex_links_last.dat", hd(links));
    nil
  end

  def filter_previously_processed(urls) do
    {:ok, file} = File.read("./docs/rinse-fm.rss")
    [_match, lastest_url] = Regex.run(~r{enclosure url="(.*?.mp3)"}, file)

    Enum.take_while(urls, &(&1 != lastest_url))
  end

  def filter_favourites(urls) do
    Enum.filter(urls, &favourite?/1)
  end

  def favourite?(url) do
    cond do
      url =~ "Huntleys.*Palmers" -> true
      url =~ ~r/UncleDugs/ -> true
      url =~ ~r/Keysound/ -> true
      url =~ ~r/Stamina/ -> true
      url =~ ~r/Hospital/ -> true
      url =~ ~r/Hessle/ -> true
      url =~ ~r/Metalhead/ -> true
      url =~ ~r/LobsterTheremin/ -> true
      url =~ ~r/Swamp81/ -> true
      true -> false
    end
  end

  def extract_infos_from_urls(urls) do
    Enum.map(urls, &extract_info_from_url/1)
  end

  def extract_info_from_url(url) do
    # urls look like:  http://podcast.dgen.net/rinsefm/podcast/Boxed300417.mp3

    # Check we have a matching string
    case Regex.run(~r/([^\/]*)(\d\d\d\d\d\d)\.mp3/, url) do
      nil ->
        IO.puts :stderr, "invalid format: #{url}"
        :invalid
      [_match, performer, date] ->
        # Check we have a valid date
        case System.cmd("date", ["-u", "-jf", "%d%m%y", date, "+%Y-%m-%d"], [stderr_to_stdout: true]) do
          {shortdate, 0} ->
            {longdate, 0} = System.cmd("date", ["-u", "-jf", "%d%m%y%H%M", date<>"0000",
                                       "+%a, %d %b %Y %H:%M:%S GMT", "2>/dev/null"])

            %{
              url: url,
              performer: performer,
              longdate: String.trim(longdate),
              shortdate: String.trim(shortdate),
            }
          _ ->
            IO.puts :stderr, "invalid date: #{url}"
            :invalid
        end
    end
  end

  def rss_items_from_url_infos(infos) do
    Enum.map(infos, &rss_item_from_url_info/1)
  end

  def rss_item_from_url_info(:invalid), do: ""
  def rss_item_from_url_info(info) do
    """
        <item>
            <title>#{info.shortdate} #{info.performer}</title>
            <enclosure url="#{info.url}" type="audio/mpeg" length="1"/>
            <guid isPermaLink="false">"guid"</guid>
            <pubDate>#{info.longdate}</pubDate>
        </item>
    """
  end
end

# ---------

{results_1, 0} = System.cmd("curl", ["-s", "http://rinse.fm/podcasts/"])
links_1 = Regex.scan(~r{download="(http://podcast\S*?)"}, results_1)
          |> List.flatten |> tl |> Enum.take_every(2)

{results_2, 0} = System.cmd("curl", ["-s", "http://rinse.fm/podcasts/?page=2"])
links_2 = Regex.scan(~r{download="(http://podcast\S*?)"}, results_2)
          |> List.flatten |> tl |> Enum.take_every(2)

{results_3, 0} = System.cmd("curl", ["-s", "http://rinse.fm/podcasts/?page=3"])
links_3 = Regex.scan(~r{download="(http://podcast\S*?)"}, results_3)
          |> List.flatten |> tl |> Enum.take_every(2)

links = [links_1, links_2, links_3] |> List.flatten

RinseFMRSSFeed.save_links(links)

# ---------

{:ok, file} = File.read("ex_links.dat")
urls = String.split(file, "\n")
       |> RinseFMRSSFeed.filter_previously_processed
       # |> RinseFMRSSFeed.filter_favourites

url_infos = RinseFMRSSFeed.extract_infos_from_urls(urls)
rss_items = RinseFMRSSFeed.rss_items_from_url_infos(url_infos)

IO.write rss_items
