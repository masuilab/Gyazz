# Gyazzの再実装

Node, Express, MongoDBで再実装するので助けて下さい (増井)

Gyazzデータは [https://github.com/masui/Gyazz]() の
Gyazz/admin/gyazz2mongo で MongoDBデータに変換できます

mongoexportしたものをどこかに置いておきます


[![Build Status](https://travis-ci.org/masuilab/Gyazz.svg?branch=master)](https://travis-ci.org/masuilab/Gyazz)


# Install Dependencies

    % npm i


## 起動

    % PORT=3000 npm start

## Debug

    % PORT=3000 DEBUG=gyazz* npm start


## Test

    % npm test
    or
    % grunt


## Deploy on Heroku

### create app

    % heroku create
    % git push heroku master

### config

    % heroku config:add TZ=Asia/Tokyo
    % heroku config:set "DEBUG=gyazz*"
    % heroku config:set NODE_ENV=production

### enable MongoDB plug-in

    % heroku addons:add mongolab
    # or
    % heroku addons:add mongohq


### logs

    % heroku logs --num 300
    % heroku logs --tail
