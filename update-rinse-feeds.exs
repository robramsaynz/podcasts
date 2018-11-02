#!/usr/bin/env elixir
#
# $ ./update-rinse-feeds.exs
# $ git add -u docs
# $ git commit "update podcasts"
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

# TODO: To remove duplicate entries
#   guid_list = File.read!(@input_file)
#               |> String.split("\n", trim: true)
#               |> Enum.map(&String.trim/1)
#               |> Enum.filter(&( &1 =~ ~r/guid/ ))
#
#   deduped_list = list |> Enum.sort |> Enum.dedup
#
#   extra items = list -- deduped


defmodule RinseFMRSSFeed do
   def run do
    # !File.write("./ex_links.dat", Enum.join(links, "\n"));
    # {:ok, file} = File.read("ex_links.dat")
    # links = String.split(file, "\n")

    links = get_links()
    update_manual_rss(links)
    update_rinse_fm_rss(links)
  end

  def get_links() do
    {results_1, 0} = System.cmd("curl", ["-s", "https://rinse.fm/podcasts/"])
    links_1 = Regex.scan(~r{download="(http://podcast\S*?)"}, results_1)
              |> List.flatten |> tl |> Enum.take_every(2)

    {results_2, 0} = System.cmd("curl", ["-s", "https://rinse.fm/podcasts/?page=2"])
    links_2 = Regex.scan(~r{download="(http://podcast\S*?)"}, results_2)
              |> List.flatten |> tl |> Enum.take_every(2)

    {results_3, 0} = System.cmd("curl", ["-s", "https://rinse.fm/podcasts/?page=3"])
    links_3 = Regex.scan(~r{download="(http://podcast\S*?)"}, results_3)
              |> List.flatten |> tl |> Enum.take_every(2)

    {results_4, 0} = System.cmd("curl", ["-s", "https://rinse.fm/podcasts/?page=4"])
    links_4 = Regex.scan(~r{download="(http://podcast\S*?)"}, results_4)
              |> List.flatten |> tl |> Enum.take_every(2)
    [links_1, links_2, links_3, links_4] |> List.flatten
  end

   # update manual.rss
  defp update_manual_rss(links) do
    urls = links
           |> RinseFMRSSFeed.Filter.filter_previously_processed("./docs/manual.rss")
           |> RinseFMRSSFeed.Filter.filter_favourites

    rss_items = urls
                |> RinseFMRSSFeed.Parse.extract_infos_from_urls
                |> RinseFMRSSFeed.Parse.rss_items_from_url_infos

    update_rss_items_in_file("./docs/manual.rss", rss_items)
  end

  # update rinse-fm.rss
  defp update_rinse_fm_rss(links) do
    urls = RinseFMRSSFeed.Filter.filter_previously_processed(links, "./docs/rinse-fm.rss")

    rss_items = urls
                |> RinseFMRSSFeed.Parse.extract_infos_from_urls
                |> RinseFMRSSFeed.Parse.rss_items_from_url_infos

    update_rss_items_in_file("./docs/rinse-fm.rss", rss_items)
  end

  defp update_rss_items_in_file(file, rss_items) do
    File.read!(file)
    |> replace_items_inside_markers(rss_items)
    |> (&File.write!(file, &1)).()
  end

  defp replace_items_inside_markers(string, rss_items) do
    arr = String.split(string, "<!-- BEGIN ITEMS -->", parts: 2)
    head = hd(arr)
    string2 = List.last(arr)
    arr2 = String.split(string2, "<!-- END ITEMS -->", parts: 2)
    tail = List.last(arr2)

    "#{head}\n"
    <> "<!-- BEGIN ITEMS -->"
    <> "#{rss_items}"
    <> "<!-- end ITEMS -->"
    <> "#{tail}"
  end
end

defmodule RinseFMRSSFeed.Filter do
  def filter_previously_processed(urls, file) do
    {:ok, file} = File.read(file)
    [_match, latest_url] = Regex.run(~r{enclosure url="(.*?.mp3)"}, file)

    if Enum.member?(urls, latest_url) do
      Enum.take_while(urls, &(&1 != latest_url))
    else
      IO.puts("""
        RinseFM feed didn't include the most recent entry (#{latest_url}) in downloaded-urls:
        [#{inspect List.last(urls)}, ..., #{inspect List.last(urls)}]
        Podcast will contain all downloaded-urls after the most recent entry, meaning there's
        probably a gap in the feed.
      """)
      urls
    end

  end

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
    performer = String.replace(info.performer, "&", "&amp;")
    url = String.replace(info.url, "&", "%26")
    guid = String.replace(info.guid, "&", "%26")

    """
        <item>
            <title>#{info.shortdate} #{performer}</title>
            <enclosure url="#{url}" type="audio/mpeg" length="1"/>
            <guid isPermaLink="false">#{guid}</guid>
            <pubDate>#{info.longdate}</pubDate>
        </item>
    """
  end
end


RinseFMRSSFeed.run()
