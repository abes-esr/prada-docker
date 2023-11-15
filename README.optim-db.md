# Optimisation de la base de données


## Nettoyage vielles données

Dans le but d'améliorer les temps de chargement parfois très long (cf difficultés été 2021) de Prada, voici la liste des requêtes qui peuvent être rejouées pour nettoyer de vielles données sans générer d'effet de bord négatifs sur Prada.


```
# Destruction des LODS de la bdd de Prada vielles de plus de 1 an.
# table: egw_log
#        egw_log_msg
# but : nettoyage des logs vielles de plus d'un an
echo "
DELETE FROM egw_log WHERE log_id IN (
  SELECT log_msg_log_id FROM egw_log_msg
  WHERE log_msg_date < now() - interval '1 year'
);

DELETE FROM egw_log_msg
WHERE log_msg_date < now() - interval '1 year';
" | docker exec -i prada-db bash -c 'PGPASSWORD="$POSTGRES_PASSWORD" psql --username=$POSTGRES_USER $POSTGRES_DB'



# Destruction des RDV Prada vieux de plus de 5 ans.
# table:  egw_cal (cal_id, cal_modified)
#         egw_cal_dates (cal_id)
#         egw_cal_extra (cal_id)
#         egw_cal_repeats (cal_id)
#         egw_cal_user (cal_id)
# memo pour debug: 
#         SELECT TO_CHAR(TO_TIMESTAMP(cal_modified), 'DD/MM/YYYY HH24:MI:SS') AS cal_modified_formated, cal_title
#         FROM egw_cal
#         WHERE TO_TIMESTAMP(cal_modified) < now() - interval '5 year' ORDER BY cal_modified DESC LIMIT 10
echo "
DELETE FROM egw_cal_dates WHERE cal_id IN (
  SELECT cal_id FROM egw_cal WHERE TO_TIMESTAMP(cal_modified) < now() - interval '5 year'
);
DELETE FROM egw_cal_extra WHERE cal_id IN (
  SELECT cal_id FROM egw_cal WHERE TO_TIMESTAMP(cal_modified) < now() - interval '5 year'
);
DELETE FROM egw_cal_repeats WHERE cal_id IN (
  SELECT cal_id FROM egw_cal WHERE TO_TIMESTAMP(cal_modified) < now() - interval '5 year'
);
DELETE FROM egw_cal_user WHERE cal_id IN (
  SELECT cal_id FROM egw_cal WHERE TO_TIMESTAMP(cal_modified) < now() - interval '5 year'
);
DELETE FROM egw_cal
WHERE TO_TIMESTAMP(cal_modified) < now() - interval '5 year';
" | docker exec -i prada-db bash -c 'PGPASSWORD="$POSTGRES_PASSWORD" psql --username=$POSTGRES_USER $POSTGRES_DB'




# Nettoyage par date d'une table volumineuse sans en connaitre son usage
# table:  egw_api_content_history
echo "DELETE FROM egw_api_content_history WHERE sync_deleted < now() - interval '5 year';
" | docker exec -i prada-db bash -c 'PGPASSWORD="$POSTGRES_PASSWORD" psql --username=$POSTGRES_USER $POSTGRES_DB'
```

## Indexes sur colonnes utiles

L'ajout d'index permet aussi d'améliorer les performances (C'est à executer une seule fois -> Déjà exécutés en 2021) :

```
CREATE INDEX "egw_cal_user_cal_user_type" ON "egw_cal_user" ("cal_user_type");
CREATE INDEX "egw_cal_user_cal_user_id" ON "egw_cal_user" ("cal_user_id");
CREATE INDEX "egw_cal_user_cal_status" ON "egw_cal_user" ("cal_status");
CREATE INDEX "egw_cal_user_cal_recur_date" ON "egw_cal_user" ("cal_recur_date");

CREATE INDEX "egw_cal_dates_cal_start" ON "egw_cal_dates" ("cal_start");
CREATE INDEX "egw_cal_dates_cal_end" ON "egw_cal_dates" ("cal_end");
CREATE INDEX "egw_cal_dates_cal_start_cal_end" ON "egw_cal_dates" ("cal_start", "cal_end");

CREATE INDEX "egw_cal_repeats_recur_type" ON "egw_cal_repeats" ("recur_type");
```


