(function(){
    var categoryOf = {
        1  : '日記',
        2  : 'コミュニティ',
        3  : 'モバイル版',
        4  : 'レビュー',
        5  : 'メッセージ',
        6  : '足あと（訪問者）',
        7  : 'お気に入り',
        8  : 'ニュース',
        9  : 'プレミアム',
        10 : 'フォト',
        11 : 'ミュージック',
        12 : '友人',
        13 : 'つぶやき',
        14 : 'ゲーム',
        15 : 'mixiページ',
        16 : 'mixiモール（ショッピング）',
        17 : 'チェック',
        18 : 'チェックイン',
        19 : 'スマートフォン版',
        20 : 'iPhoneアプリ',
        21 : 'Androidアプリ',
        22 : 'パソコン版',
        23 : 'カレンダー',
        24 : '同級生・同僚',
        25 : '機能要望',
        26 : 'プロフィール',
        27 : 'mixiパーク',
        28 : 'アクセスブロック',
        29 : '友人を探す',
        30 : 'コメント/イイネ',
        31 : '動画',
        32 : 'mixiバースデー',
        33 : '3DS版',
        34 : '検索機能',
        35 : 'mixiポイント',
        36 : '新着お知らせ枠',
        37 : '友人の更新情報(タイムライン)',
        38 : '新着お知らせ枠(イイネ・コメント通知)',
        39 : 'mixi新規登録',
        40 : 'メルマガ',
        99 : 'その他'
    };

    function Background(){
        this.initialize.apply(this, arguments);
    }
    Background.prototype = {
        initialize: function() {
            this.view = new View();
            this.mainModel = new Model({type:"main", method:"lookup"});
            this.bodyModel = new Model({type:"body", method:"lookup"});
            this.rankModel = new Model({type:"rank", method:"find"});
            this.currentItemSize = 6;
            this.assignInitialContents();
            this.assignEventHandlers();
            console.log("init.");
        },
        assignEventHandlers: function(){
            var _self = this;
            $('#showMoreButton').click(function(){
                var jButton = $(this);
                jButton.attr("disabled","disabled");
                _self.getIdeaEntities({
                    limit  : 6,
                    offset : _self.currentItemSize,
                    order  : 'DESC',
                    gt_tendency : 100
                }).done(function(entities){
                    _self.view.appendEntities(entities);
                    _self.currentItemSize += 6;
                    jButton.removeAttr("disabled");
                });
            });
        },
        assignInitialContents: function(){
            var _self = this;
            this.getIdeaEntities({
                limit  : this.currentItemSize,
                offset : 0,
                order  : 'DESC'
            }).done(function(entities){
                _self.view.appendEntities(entities);
            });
        },
        getIdeaEntities: function(params){
            var _self = this;
            var dfd = $.Deferred();
            var entities  = [];
            this.rankModel.request(params).pipe(function(response){
                var rankArray = response.result;
                var batchData = [];
                for(var i=0;i<rankArray.length;i++){
                    var id = rankArray[i].idea_id;
                    var tendency = rankArray[i].tendency;
                    entities.push(new IdeaEntity({id:id,tendency:tendency}));
                    batchData.push({"id":id});
                }
                return _self.mainModel.batchRequest(batchData);
            }).pipe(function(results){
                var batchData = [];
                for(var i=0;i<results.length;i++){
                    var result = results[i].result;
                    entities[i].setTitle(result.title);
                    entities[i].setCategoryId(result.category_id);
                    entities[i].setCount({
                        positive: result.positive_point,
                        negative: result.negative_point
                    });
                    entities[i].updatedAt = result.updated_at;
                    batchData.push({id:result.idea_id});
                }
                return _self.bodyModel.batchRequest(batchData);
            }).pipe(function(results){
                for(var i=0;i<results.length;i++){
                    var result = results[i].result;
                    entities[i].setDetail(result.body);
                }
                dfd.resolve(entities);
            });
            return dfd.promise();
        }
    };

    function View(){
        this.initialize.apply(this, arguments);
    }
    View.prototype = {
        initialize: function(arguments) {
            this.baseHtml = $('#container_template').html();
            this.templateName = "containerTemplate";
            $.template(this.templateName, this.baseHtml);
        },
        appendEntities: function(entities){
            for(var i=0; i<entities.length; i++){
                var newEntity = $.tmpl(this.templateName, entities[i]);
                console.log(newEntity);
                $('#contents_area_main')
                    .masonry({
                        isAnimated: true,
                        animationOptions: {
                            duration: 400
                        }
                    })
                    .append(newEntity)
                    .masonry('reload');
            }
        }
    };

    function Model(){
        this.initialize.apply(this, arguments);
    }
    Model.prototype = {
        initialize: function(arguments) {
            this.modelType = arguments.type;
            this.method    = arguments.method;
            this.endPoint  = "/api/" + this.modelType + "/rpc.json";
        },
        batchRequest: function(paramArray){
            var _self = this;
            var data = [];
            for(var i=0; i<paramArray.length; i++){
                data.push({
                   jsonrpc : '2.0',
                   method  : this.method,
                   params  : paramArray[i],
                   id      : i+1
                });
            }
            return $.ajax({
                type          : 'POST',
                url           : this.endPoint,
                dataType      : 'json',
                contentType   : 'application/json',
                scriptCharset : 'utf-8',
                data          : JSON.stringify(data)
            }).fail(function(jqXHR, textStatus) {
                console.log( "Request failed: " + textStatus );
            });
        },
        request: function(params){
            var _self = this;
            var data = {
               jsonrpc : '2.0',
               method  : this.method,
               params  : params,
               id      : 1
            };
            return $.ajax({
                type          : 'POST',
                url           : this.endPoint,
                dataType      : 'json',
                contentType   : 'application/json',
                scriptCharset : 'utf-8',
                data          : JSON.stringify(data)
            }).fail(function(jqXHR, textStatus) {
                console.log( "Request failed: " + textStatus );
            });
        }
    };

    function IdeaEntity(){
        this.initialize.apply(this, arguments);
    }
    IdeaEntity.prototype = {
        initialize: function(arguments) {
            this.id = arguments.id;
            this.tendency = arguments.tendency;
        },
        setTitle: function(title){
            this.title = title;
        },
        setDetail: function(detail){
            this.detail = detail;
        },
        setCategoryId: function(id){
            this.categoryId = id;
            this.category   = categoryOf[id];
        },
        setCount: function(countObj){
            this.positiveCount = parseInt(countObj.positive, 10);
            this.negativeCount = parseInt(countObj.negative, 10);
            this.positivePercentage = Math.floor(this.positiveCount*100/(this.positiveCount+this.negativeCount));
            this.negativePercentage = 100-this.positivePercentage;
        },
        as_hash: function(){
            return {
                id: this.id,
                tendency: this.tendency,
                title: this.title,
                detail: this.detail,
                categoryId: this.categoryId,
                category: this.category,
                updatedAt: this.updatedAt,
                positiveCount: this.positiveCount,
                negativeCount: this.negativeCount,
                positivePercentage: this.positivePercentage,
                negativePercentage: this.negativePercentage
            };
        }
    };

    $(document).ready(function(){
        var bg = new Background();
    });
})();

