#!/usr/bin/env elixir
#
# $ ./update-manual-feed.exs
# $ git add -u docs
# $ git commit "update podcasts"
#
# TODO: get the date to stop having what should be a static date move.
#  ie this happens:
#      -        <pubDate>Fri, 05 Oct 2018 00:00:31 GMT</pubDate>
#      +        <pubDate>Fri, 05 Oct 2018 00:00:41 GMT</pubDate>
#
# TODO: Convert this to pull out the title/date/etc
#   <div id="naafi030118" class="borderbottom left podcast-list-item">...
#     <div class="left w8-16">
#       <h3 class="darkgrey tstarheavyupper px15 mb8">NAAFI</h3>
#       ...
#       <div class="listen icon">
#         <a href="http://podcast.dgen.net/rinsefm/podcast/NAAFI030118.mp3" class="bglightblue" onclick="__gaTracker('send', 'event', 'openpodcastinplayer', 'podcastpage', 'Podcast: NAAFI');" data-airtime="1" data-air-day="2018-01-04" data-artist="NAAFI">&nbsp;</a>
#       </div>
#       ...
#       <div class="right">
#         <div class="date tstarregular grey px12 mt0">01:00 - 03:00 </div>
#         ...
#       </div>
#     </div>
#   </div>

defmodule RinseFMRSSFeed do
   def run do
    # !File.write("./ex_links.dat", Enum.join(links, "\n"));
    # {:ok, file} = File.read("ex_links.dat")
    # links = String.split(file, "\n")

    links = get_links!()
    update_manual_rss(links)
  end

  def get_links!() do
    # TODO: turn this into, get_podcast_page(int)

    {results_1, 0} = System.cmd("curl", ["-s", "https://rinse.fm/podcasts/"])
    {results_2, 0} = System.cmd("curl", ["-s", "https://rinse.fm/podcasts/?page=2"])
    {results_3, 0} = System.cmd("curl", ["-s", "https://rinse.fm/podcasts/?page=3"])
    {results_4, 0} = System.cmd("curl", ["-s", "https://rinse.fm/podcasts/?page=4"])

    if (results_1 == [] || results_2 == [] || results_3 == [] || results_4 == []), do:
      raise "could not download rinse fm pages"

    downloads_1 = Regex.scan(~r{download="(http://\S*?)"}, results_1)
    downloads_2 = Regex.scan(~r{download="(http://\S*?)"}, results_2)
    downloads_3 = Regex.scan(~r{download="(http://\S*?)"}, results_3)
    downloads_4 = Regex.scan(~r{download="(http://\S*?)"}, results_4)

    if (downloads_1 == [] || downloads_2 == [] || downloads_3 == [] || downloads_4 == []), do:
      raise "could not get download= elements from rinse fm pages"

    links_1 = downloads_1 |> List.flatten |> tl |> Enum.take_every(2)
    links_2 = downloads_2 |> List.flatten |> tl |> Enum.take_every(2)
    links_3 = downloads_3 |> List.flatten |> tl |> Enum.take_every(2)
    links_4 = downloads_4 |> List.flatten |> tl |> Enum.take_every(2)

    [links_1, links_2, links_3, links_4] |> List.flatten
  end

   # update manual.rss
  defp update_manual_rss(links) do
    urls = RinseFMRSSFeed.Filter.filter_favourites(links)

    rss_items = urls
                |> RinseFMRSSFeed.Parse.extract_infos_from_urls
                |> RinseFMRSSFeed.Parse.remove_invalid_urls
                |> RinseFMRSSFeed.Parse.de_duplicate_guids
                |> RinseFMRSSFeed.Parse.rss_items_from_url_infos

    update_rss_items_in_file("./docs/manual.rss", rss_items)
  end

  defp update_rss_items_in_file(file, rss_items) do
    File.read!(file)
    |> insert_items_at_top_of_list_markers(rss_items)
    |> (&File.write!(file, &1)).()
  end

  defp insert_items_at_top_of_list_markers(string, rss_items) do
    arr = String.split(string, "<!-- BEGIN ITEMS -->", parts: 2)
    head = hd(arr)
    tail = List.last(arr)

    IO.puts "WARNING: This should find the last existing guid and remove it if necessary\n"

    "#{head}"
    <> "<!-- BEGIN ITEMS -->\n"
    <> "#{rss_items}"
    <> "#{tail}"
  end
end

defmodule RinseFMRSSFeed.Filter do
  def filter_favourites(urls) do
    Enum.filter(urls, &favourite?/1)
  end

  def favourite?(url) do
    cond do
      url =~ "Huntleys.*Palmers" -> true
      url =~ ~r/Uncle.?Dugs/i -> true
      url =~ ~r/Keysound/i -> true
      url =~ ~r/Stamina/i -> true
      url =~ ~r/Hospital/i -> true
      url =~ ~r/Hessle/i -> true
      url =~ ~r/Metalhead/i -> true
      url =~ ~r/Lobster.?Theremin/i -> true
      url =~ ~r/Swamp81/i -> true
      url =~ ~r/Hodge/i -> true
      url =~ ~r/Auntie.?Flo/i -> true
      url =~ ~r/Critical.?Music/i -> true
      true -> false
    end
  end
end

defmodule RinseFMRSSFeed.Parse do
  def extract_infos_from_urls(urls) do
    Enum.map(urls, &extract_info_from_url/1)
  end

  def remove_invalid_urls(urls) do
    Enum.reject(urls, &( &1 == :invalid ))
  end

  # for repeated guids, take the first one.
  def de_duplicate_guids(url_infos), do: de_duplicate_guids(url_infos, [])
  def de_duplicate_guids([head | tail], acc) do
    entry = {String.to_atom(head[:guid]), head}
    de_duplicate_guids(tail, [entry | acc])
  end
  def de_duplicate_guids([], acc) do
    # Keyword.new/1 preserves the last version of repeated values (in the
    # reversed list, ie original topmost entry)
    Keyword.new(acc)
    |> Enum.reverse
    |> Keyword.values
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
            {longdate, 0} = System.cmd("date", ["-u", "-jf", "%d%m%y%H%M%S", date<>"000000",
                                       "+%a, %d %b %Y %H:%M:%S GMT", "2>/dev/null"])

            # TODO: convert this to a struct
            %{
              url: url,
              guid: url,
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
    performer = html_escape(info.performer)
    url = html_escape(info.url)
    # url = URI.encode(info.url, &( URI.char_unescaped?(&1) && &1 != ?? && &1 != ?/ ))
    guid = html_escape(info.guid)

    """
        <item>
            <title>#{info.shortdate} #{performer}</title>
            <enclosure url="#{url}" type="audio/mpeg" length="1"/>
            <guid isPermaLink="false">#{guid}</guid>
            <pubDate>#{info.longdate}</pubDate>
        </item>
    """
  end

  # Only %-escape & < and > chars.
  defp html_escape(string) do
    URI.encode(string, &( &1 != ?? && &1 != ?< && &1 != ?> ))
  end
end


RinseFMRSSFeed.run()
