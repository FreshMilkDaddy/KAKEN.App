##########################
# パッケージの読み込み
##########################

library(dplyr)
library(tidyr)
library(purrr)
library(stringr)
library(data.table)
library(igraph)
library(threejs)
library(data.table)

# データインポート
d <- fread("../99_cleaned_data/cleaned_df.csv")


##########################
# データの整形
##########################


# --------------------------
# 共同研究者列の展開と整理
# --------------------------

D0 <- d %>% filter(研究分担者 != "") %>%
    mutate(代表ID = str_extract(研究代表者, "\\d{8}")) %>%
    mutate(分担者 = str_split(研究分担者, "\n")) %>% 
    unnest(cols = 分担者) %>%
    mutate(分担ID = str_extract(分担者, "\\d{8}")) %>%
    mutate(分担所属 = str_extract(分担者, "^.+?(?=,)")) %>%
    mutate(分担所属 = str_replace(分担所属, "(^.+ )(.+$)", "\\2")) %>%
    select(研究課題番号, 研究種目, 総配分額, 年度, 区分, 区分名, 代表ID, 分担ID, 所属機関, 分担所属) %>%
    mutate(分担所属 = str_replace(分担所属, "^国立研究開発法人", "")) %>%
    mutate(分担所属 = str_replace(分担所属, "^公益財団法人", "")) %>%
    mutate(分担所属 = str_replace(分担所属, "^大学共同利用機関法人", "")) %>%
    mutate(分担所属 = str_replace(分担所属, "^独立行政法人", "")) %>%
    mutate(分担所属 = str_replace(分担所属, "^地方独立行政法人", "")) %>%
    mutate(分担所属 = str_replace(分担所属, "^一般財団法人", "")) %>%
    mutate(分担所属 = str_replace(分担所属, "株式会社", "")) %>%
    mutate(分担所属 = str_replace(分担所属, "産業技術総合研究所", "産総研")) %>%
    mutate(分担所属 = str_replace(分担所属, "理化学研究所", "理研")) %>%
    mutate(分担所属 = str_replace(分担所属, "^国立文化財機構", "")) %>%
    mutate(分担所属 = str_replace(分担所属, "大学$", "")) %>%
    mutate(分担所属 = ifelse(str_detect(分担所属, "国立国語研究所"), "国立国語研究所", 分担所属))


# --------------------------
#  研究者組み合わせ関数
# --------------------------

com <- function(x){
    c(x$代表ID, x$分担ID) %>%
        unique() %>%
        combn(2) %>%
        t %>%
        as.data.frame()
}


# ---------------------------------
# 研究者の組み合わせデータフレーム 
# ---------------------------------

# メモリを大量に消費するので、年度別に分けて処理

DF2018 <- D0 %>% filter(年度 == 2018) %>%
    nest(-年度, -研究課題番号, -研究種目, -区分名) %>%
    mutate(clean = map(data, com)) %>% select(-data) %>%
    unnest(clean)

DF2019 <- D0 %>% filter(年度 == 2019) %>%
    nest(-年度, -研究課題番号, -研究種目, -区分名) %>%
    mutate(clean = map(data, com)) %>% select(-data) %>%
    unnest(clean)

DF_all <- rbind(DF2018, DF2019) %>%
    select(V1, V2, 研究課題番号, 研究種目, 年度, 区分名)

DF_all %>% fwrite("../99_cleaned_data/network.csv")



# --------------------------
#  研究者リスト 
# --------------------------

Res.list <- bind_rows(
    D0 %>% select(年度, 代表ID, 所属機関) %>% rename("ID" = "代表ID", "所属" = "所属機関"),
    D0 %>% select(年度, 分担ID, 分担所属) %>% rename("ID" = "分担ID", "所属" = "分担所属")
) %>% unique

Res.list %>% fwrite("../99_cleaned_data/researcher.csv")




