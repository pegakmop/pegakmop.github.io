	$.ajax({
			 		async: true,
			 		crossDomain: true,
					url: 'https://kinopoiskapiunofficial.tech/api/v2.2/films/top?type=TOP_100_POPULAR_FILMS&page=1',
					type: 'GET',
			 		headers: {'X-API-KEY':'1281ba0d-593b-4f3e-8b14-2b63e66ae00a'},
					success: function(response){
	         				var a = response.films;
			 				var index, len;
			 				for (index = 0, len = a.length; index < len; ++index) {
				 				var item = a[index];
					 				 $('.items').append('<li class="item" style="margin-bottom: 1rem">    <a class="link" href="/films?id='+item.filmId+'&title='+item.nameRu+' ('+item.year+')"  title="'+item.nameRu+' ('+item.year+')">        <div class="cover-wrap">          <div class="cover js-b-lazy fadeIn animated" style="background-image: url('+item.posterUrlPreview+');"></div></div>     <div class="description">     <h3 class="title">'+item.nameRu+'</h3>      <span class="desc">     <span class="rating">'+item.rating+'</span>    <span class="year">'+item.year+'</span></span></div></a></li>');
							}
					}
	});
	 
	$.ajax({
			 		async: true,
			 		crossDomain: true,
					url: 'https://kinopoiskapiunofficial.tech/api/v2.2/films/top?type=TOP_100_POPULAR_FILMS&page=2',
					type: 'GET',
			 		headers: {'X-API-KEY':'1281ba0d-593b-4f3e-8b14-2b63e66ae00a'},
					success: function(response){
	         				var a = response.films;
			 				var index, len;
			 				for (index = 0, len = a.length; index < len; ++index) {
				 				var item = a[index];
					 				 $('.items').append('<li class="item" style="margin-bottom: 1rem">    <a class="link" href="/films?id='+item.filmId+'&title='+item.nameRu+' ('+item.year+')"  title="'+item.nameRu+' ('+item.year+')">        <div class="cover-wrap">          <div class="cover js-b-lazy fadeIn animated" style="background-image: url('+item.posterUrlPreview+');"></div></div>     <div class="description">     <h3 class="title">'+item.nameRu+'</h3>      <span class="desc">     <span class="rating">'+item.rating+'</span>    <span class="year">'+item.year+'</span></span></div></a></li>');
							}
					}
	});
	 
	$.ajax({
			 		async: true,
			 		crossDomain: true,
					url: 'https://kinopoiskapiunofficial.tech/api/v2.2/films/top?type=TOP_100_POPULAR_FILMS&page=3',
					type: 'GET',
			 		headers: {'X-API-KEY':'1281ba0d-593b-4f3e-8b14-2b63e66ae00a'},
					success: function(response){
	         				var a = response.films;
			 				var index, len;
			 				for (index = 0, len = a.length; index < len; ++index) {
				 				var item = a[index];
					 				 $('.items').append('<li class="item" style="margin-bottom: 1rem">    <a class="link" href="/films?id='+item.filmId+'&title='+item.nameRu+' ('+item.year+')"  title="'+item.nameRu+' ('+item.year+')">        <div class="cover-wrap">          <div class="cover js-b-lazy fadeIn animated" style="background-image: url('+item.posterUrlPreview+');"></div></div>     <div class="description">     <h3 class="title">'+item.nameRu+'</h3>      <span class="desc">     <span class="rating">'+item.rating+'</span>    <span class="year">'+item.year+'</span></span></div></a></li>');
							}
					}
	});
	
function search(){
	var text = document.getElementById('text').value;
	$.ajax({
			 		async: true,
			 		crossDomain: true,
					url: 'https://kinopoiskapiunofficial.tech/api/v2.1/films/search-by-keyword?keyword='+text,
					type: 'GET',
			 		headers: {'X-API-KEY':'1281ba0d-593b-4f3e-8b14-2b63e66ae00a'},
					success: function(response){
							$('.title').empty();
							$('.items').empty();
	         				var a = response.films;
			 				var index, len;
			 				for (index = 0, len = a.length; index < len; ++index) {
				 				var item = a[index];
					 				 $('.items').append('<li class="item" style="margin-bottom: 1rem">    <a class="link" href="/films?id='+item.filmId+'&title='+item.nameRu+' ('+item.year+')"  title="'+item.nameRu+' ('+item.year+')">        <div class="cover-wrap">          <div class="cover js-b-lazy fadeIn animated" style="background-image: url('+item.posterUrlPreview+');"></div></div>     <div class="description">     <h3 class="title">'+item.nameRu+'</h3>      <span class="desc">     <span class="rating">'+item.rating+'</span>    <span class="year">'+item.year+'</span></span></div></a></li>');
							}
					}
	});
	};
	
$(document).ready(function(){
                 $("#text").keypress(function(e){
                   if(e.keyCode==13){
                   //нажата клавиша enter - здесь ваш код
                   search();
                   }
                 });
 
             });
