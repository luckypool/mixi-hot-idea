(function(){
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
            console.log("init.");
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
        appendContainer: function(params){
            var positive_count = parseInt(params.positive_count, 10);
            var negative_count = parseInt(params.negative_count, 10);
            var positive_percentage = Math.floor(positive_count*100/(positive_count+negative_count));
            params.positive_percentage = positive_percentage;
            params.negative_percentage = 100-positive_percentage;
            $.tmpl(this.templateName, params).appendTo('#contents_area_main');
        },
        appendEntities: function(entities){
            for(var i=0; i<entities.length; i++){
                $.tmpl(this.templateName, entities[i]).appendTo('#contents_area_main');
            }
            $('#contents_area_main').masonry({
                isAnimated: true,
                isFitWidth: true,
                animationOptions: {
                    duration: 400
                }
            });
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
            this.category   = 'DUMMY';
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

