Got the dataset from Sackmann from GitHub.
Verified for orphaned player references before adding foreign keys and found none.
Checked that every tournament has a distinct tourney_id, so it can be a PK
Checked if one tournament can have more than one surface, the answer was no, so the surface can be a column on the Tournament table
Checked if every match_num is unique on every tournament, it is. So now if I want to use this as a FK, I have to carry both columns.
I found the first problem, although every player_id is unique, there is some trouble with rankings, where the same ranking_date and player_id can have different rankings, this is most likely due to either bad data or different formattings.
Some of the duplicates were because of bad data upload, but there are 120 players that have duplicated data (780 rows).
Out of those, find out 181, where identical, meaning the same row duplicated, and 599 where conflicting meaning same player, same week, different ranking.
I will just select one of the identicals, and regarding the confliciting I will just remove all of them, for time purposes. Another project with more time I would find a way to solve it.
There are 6 categories of tournament levels: A for other tour-level events, D for Davis Cup, F for Tour Finals and other season ending events, G for Grand Slams, M for Masters, S for Satellites/ITFs, and C for Challengers.

Surface can be Hard, Clay, Carpet, Grass, or NULL

HAND can be A for Ambidiextrous, L for Lefty, R for Righty, U for Unspecified, or NULL

For winner and loser entry: Q=qualifier, WC=wild card, LL=lucky loser, PR=protected ranking, SE=special exempt, ALT=alternate, W=withdrawal-related, ITF=ITF entry, NG=national group, UP for Universality Place, or NULL.

Looking at entrys, there are some inconsitencies: 
Alt and ALT, using UPPER() should fix it
There are other inconsistencies like L, S, and W. Runed a command to see the matches that were in and checked every match, they were all abreviations for LL, SE, and WC.
I will just need to entry a normalization rule:
CASE UPPER(NULLIF(entry,''))
  WHEN 'L' THEN 'LL'
  WHEN 'W' THEN 'WC'
  WHEN 'S' THEN 'SE'
  ELSE UPPER(NULLIF(entry,''))
END

I also checked the best_of, there are 36 matches recorded as best of 1 set, all of them legit but there is one that should be a three set. It is missing the space. When I transform I will have to add a CASE expression:
CASE
  WHEN score = '6-36-3' THEN '6-3 6-3'
  ELSE score
END

In addition, some of the 1 set matches are either going to 8, 10, 31, or 6 by difference of 1. So something to keep in mind.

I have not added a age column for the players in the match table, I will just compute that by subtracting the tournament date to the dob.

Regarding the rounds, I found that ER stands for Entry Round, a format that was tried at the beginning of 2007 and only applied to 4 tournaments. It was a round used before the Round Robin, as an elimination round.

There are players where no height is entered. And there were eight players with unusual heights, anywhere from 3, 15, 13, to 71 or 132. Any of those heights made sense, and decided to nullyfing them rather than giving a guess. The two that were 71, had the theory that could be inches rather than cm, but uppon verification, it was not consistent so decided to nullify all:
CASE WHEN NULLIF(height,'')::INT BETWEEN 140 AND 230
     THEN NULLIF(height,'')::INT
     ELSE NULL END

There were some fields that had empty strings, I will use NULLIF(column, '') . The columns are surface, player_entry, hand.

Saw there were two matches that were a W/O but had minutes played, after checking realized it was bad data and that the matches were actually not played due to W/O, so I will fix that when creating the table

When I tried to upload the match_stats, I got a problem with a match that had the same player_id for the winner and loser. After doing some research, the player_id = '199999' is UNKNOWN. There were three matches where both players were unknown, so I decided to exclude them, there are 87 mathces where one of the two is unknown, I decided to keep those since they still give me information about the other player. 

Had another problem, this time with bpsaved. There were two matches that had negative loser break points saved. I decided to nullify both bpsaved, and bpfaced on the loser side.