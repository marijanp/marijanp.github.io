---
title: NixOS Ocean Sprint October 2023 - A report
author: Marijan
description: A report about the NixOS Ocean Sprint which is the ideal opportunity to meet fellow contributors and users from the Nix community. People from all over the world gathered in one house on the sunny Canary Island of Lanzarote to contribute and share insights or discuss topics about the Nix ecosystem. In addition, in between coding sessions, there are plenty of exciting activities like diving, surfing, cycling, drumming, etc. one can do together with amazing people.
---

The NixOS Ocean Sprint [oceansprint.org](https://oceansprint.org/) is the ideal opportunity to meet fellow contributors and users from the Nix community.
People from all over the world gathered in one house on the sunny Canary Island of Lanzarote to contribute and share insights or discuss topics about the Nix ecosystem.
In addition, in between coding sessions, there are plenty of exciting activities like diving, surfing, cycling, drumming, etc. one can do together with amazing people.

For that reason, I have been participating for the second time now!

In the following article, I will go into more detail about the location, the daily schedule, the projects people worked on, and the activities we did at the October 2023 sprint.

But first, let me start with a big thank you to the event's organizers: Neyts Zupan, Domen Kožar, and Florian Friesdorf.

## The Location

As the name "Ocean Sprint" suggests, the location of the sprint was close to the ocean, more precisely on the Canary Island of Lanzarote at the Atlantic Ocean.
The sprint's venue was a beautiful villa in the town of Costa Teguise called [Niteo House](https://house.niteo.co/), providing enough space for 30 people and a water cooling solution for hackers (a pool), which is more than needed with outside temperatures of about 28°C (82.4°F).

## The Schedule

The opening of the sprint happened on the Sunday evening before the sprint week.
The participants met at a local restaurant and had dinner together.
Unfortunately, I arrived late because I landed at 8 p.m. and missed the welcoming speech and the briefing.
But I was informed that it was the same as in the past: everyone was welcomed, and rules regarding the venue and social rules (only speak English, wear your nametag) were made.
Last but not least, there was a shout-out to the amazing [sponsors](https://oceansprint.org/#sponsors) who make awesome events like this happen!

The daily schedule during the sprint looked like the following:

Some of the participants woke up quite early to have a swim at the beach and to enjoy the beautiful sunrise.

Starting from 9 p.m. the breakfast buffet opened at the venue. From then on, the participants began to arrive one by one. The main topic at breakfast was Nix and the projects people were working on (who would have guessed). The transition from breakfast to productive work was seamless. People naturally continued to work on their topics until lunch.

Lunch was served at the venue, too, and fulfilled the purpose of a necessary break between working sessions.

Some afternoons have been reserved for organized joint activities, where people could join in case they needed a break without any obligations (I will give you an idea about some of the activities in more detail later).
The afternoon work session continued until the daily stand-up at 7 p.m., where people had the chance to inform others about their progress or the blockers they experienced.
Afterward, we had dinner together. Like Paella, authentic Neapolitan pizza made by a fellow Italian software engineer, and even freshly caught tuna steaks grilled by Neyts (one of the organizers).

And on most evenings after dinner, some people didn't have enough Nix during the day and continued to be productive. A wise choice, given that you probably won't have a chance anytime soon to work in person.

```{=html}
<figure>
    <img class="m-auto md:h-72" src="/images/nixos-oceansprint-2023-10/pizza.jpg"
         alt="Authentic Neoplitan pizza." >
    <figcaption class="m-auto text-center">Authentic Neapolitan pizza made by a fellow Italian software engineer</figcaption>
</figure>
```

## The projects

In the following, I've tried to summarize some of the projects people were working on, but this is just a fraction of what was done. To get a more detailed overview, we maintained a daily stand-up transcript, which you can find [here](https://pad.lassul.us/os23-projects).

### lighthouse-flake

With the help of David ([@DavHau](https://github.com/DavHau)) and Johannes ([@hsjobeki](https://github.com/hsjobeki)), I finally managed to package [Google lightouse](https://github.com/GoogleChrome/lighthouse) a web page and web app auditing tool. It was packaged using [dream2nix](https://github.com/nix-community/dream2nix) and was added to [dreampkgs](https://github.com/nix-community/dreampkgs/blob/main/packages/lighthouse/default.nix).

Packaging Google lighthouse was the first step towards creating [lighthouse-flake](https://github.com/marijanp/lighthouse-flake), which is a [flake-parts](https://flake.parts/) module that enables you to add one or more audit checks to your flake by simply defining the path to your frontend and the criteria score (performance, accessibility, SEO, and best-practices) you want to be met.

### Perlless Activation

Niklas ([@nikstur](https://github.com/nikstur)), Julian ([@blitz](https://github.com/blitz)), and Linus ([@lheckemann](https://github.com/lheckemann)) worked on getting rid of all of the in Perl implemented activation scripts, since they are legacy leftovers from the SystemV era and can be replaced using systemd features (e.g. ExecPreStart, separate services). By removing the Perl activation scripts, we should expect an overall increase in efficiency during boot. For more details about their implementation plan and their approach [click here](https://pad.lassul.us/perlless-activation).

### Improve Evaluation Performance of Strings

Tom ([@tomberek](https://github.com/tomberek)) worked on introducing an alternative string implementation to improve the evaluation performance of strings, which is `O(N^2)` in some cases. The idea was to use a [rope data structure](<https://en.wikipedia.org/wiki/Rope_(data_structure)>), which makes concatenation and memory usage more efficient.

### Better User Experience when running NixOS Tests on a Mac

NixOS tests are one of the most powerful features of the NixOS ecosystem as they allow one to system test one or more virtual machines and their interactions (for a quick overview [click here](https://nixcademy.com/2023/10/24/nixos-integration-tests/)). Jacek's [@tfc](https://github.com/tfc/) plan to achieve a better user experience for Mac users was to automatically set up a Linux remote-builder to be able to build the required dependencies for the NixOS test. When the NixOS machines, defined in the test, get spawned as qemu-VMs the dependencies required by each machine get copied respectively.

### nixpkgs-merge-bot

[lassulus](https://github.com/lassulus) and [Mic92](https://github.com/Mic92/) worked together on the [nixpkgs-merge-bot](https://github.com/nixos/nixpkgs-merge-bot). The bot was designed to help nixpkgs maintainers merge pull requests that involve changes to their own packages. The bot enables maintainers to efficiently respond to user feedback and perform self-service merges. The bot is limited to packages within the "pkgs/by-name" directory in nixpkgs.

```{=html}
<figure>
    <img class="m-auto md:h-72" src="/images/nixos-oceansprint-2023-10/pool.jpg"
         alt="Lassulus, Mic92 and Kranzes about to deploy nixpkgs-merge-bot.">
    <figcaption class="m-auto text-center">Lassulus, Mic92 and Kranzes about to deploy nixpkgs-merge-bot.</figcaption>
</figure>
```

### GPU Access in the Nix Sandbox

Sergej [@SomeoneSerge](https://github.com/someoneserge) wrapped up his [pull request](https://github.com/NixOS/nixpkgs/pull/256230) to allow exposing devices and drivers (most importantly GPUs) by setting the new `requiredSystemFeatures` to e.g. `["cuda"]`.

## The Activities

Because pictures say more than a thousand words: here are some impressions from the various activities (surfing, diving, drumming, etc.) people were able to participate in.

```{=html}
<div class="carousel carousel-center rounded-box bg-neutral p-4 space-x-4 not-prose w-full">
    <div class="carousel-item">
        <figure>
            <img class="rounded-box max-h-72" src="/images/nixos-oceansprint-2023-10/boat_trip_0.jpg" alt="Ocean Sprint participants on a boat">
            <figcaption class="text-center">The whole group went on a boat trip on one afternoon</figcaption>
        </figure>
    </div>
    <div class="carousel-item">
        <figure>
            <img class="rounded-box max-h-72" src="/images/nixos-oceansprint-2023-10/boat_trip_1.jpg" alt="Ocean Sprint solving problems on a boat">
            <figcaption class="text-center">Even on the boat the main topic was Nix</figcaption>
        </figure>
    </div>
    <div class="carousel-item">
        <figure>
            <img src="/images/nixos-oceansprint-2023-10/wine_tasting_2.jpg" alt="Photograph of the Ocean Sprint participants listening to the guided winery tour" class="rounded-box max-h-72">
            <figcaption class="text-center">We had a guided tour through a winery</figcaption>
        </figure>
    </div>
    <div class="carousel-item">
        <figure>
            <img src="/images/nixos-oceansprint-2023-10/wine_tasting_0.jpg" alt="Photograph wine tasting" class="rounded-box max-h-72">
            <figcaption class="text-center">Wine tasting after the guided tour</figcaption>
        </figure>
    </div>
    <div class="carousel-item">
        <figure>
            <img src="/images/nixos-oceansprint-2023-10/wine_tasting_1.jpg" alt="Photograph inside the winery" class="rounded-box max-h-72">
            <figcaption class="text-center">Inside the winery</figcaption>
        </figure>
    </div>
    <div class="carousel-item">
        <figure>
            <img class="rounded-box max-h-72" src="/images/nixos-oceansprint-2023-10/diving.jpg" alt="Ocean Sprint participants after diving">
            <figcaption class="text-center">Some participants went diving</figcaption>
        </figure>
    </div>
    <div class="carousel-item">
        <figure>
            <img class="rounded-box max-h-72" src="/images/nixos-oceansprint-2023-10/surfing_0.jpg" alt="Famara beach">
            <figcaption class="text-center">Others took surfing classes at Famara beach</figcaption>
        </figure>
    </div>
    <div class="carousel-item">
        <figure>
            <img class="rounded-box max-h-72" src="/images/nixos-oceansprint-2023-10/surfing_1.jpg" alt="Ocean Sprint participant surfing">
            <figcaption class="text-center">Some participants took surfing classes</figcaption>
        </figure>
    </div>
    <div class="carousel-item">
        <figure>
            <img class="rounded-box max-h-72" src="/images/nixos-oceansprint-2023-10/surfing_2.jpg" alt="Ocean Sprint participant surfing">
            <figcaption class="text-center">Some participants took surfing classes</figcaption>
        </figure>
    </div>
    <div class="carousel-item">
        <figure>
            <img class="rounded-box max-h-72" src="/images/nixos-oceansprint-2023-10/surfing_3.jpg" alt="Ocean Sprint participant surfing">
            <figcaption class="text-center">Some participants took surfing classes</figcaption>
        </figure>
    </div>
    <div class="carousel-item">
        <figure>
            <img class="rounded-box max-h-72" src="/images/nixos-oceansprint-2023-10/drumming.jpg" alt="Ocean Sprint participants taking a drumming class">
            <figcaption class="text-center">And others took drumming classes</figcaption>
        </figure>
    </div>
</div>
```

## Summary

The NixOS Ocean Sprint is the perfect opportunity to spend time with great people who have the same interest in Nix as you might have. If you are working alone on a project and have a problem, there will be someone there to help you with it, and if you work on a problem with someone else, you benefit from the invaluably high communication frequency. Moreover, it doesn't matter how experienced you are. Everyone is welcome, and no question is left unanswered. I personally love to listen and absorb all the discussions revolving around Nix that are omnipresent. And, of course, the activities and the great weather only add to the experience.

<img src="/images/nixos-oceansprint-2023-10/group.jpg" alt="Ocean Sprint participants group photo">
