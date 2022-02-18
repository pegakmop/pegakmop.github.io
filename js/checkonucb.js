	var searchString = new URLSearchParams(window.location.search);
	const id = searchString.get('id');
	const TLT = encodeURI(searchString.get('title'));
	
	$.ajax({
			 		async: true,
			 		crossDomain: true,
					url: 'https://kinopoiskapiunofficial.tech/api/v2.2/films/'+id+'/similars',
					type: 'GET',
			 		headers: {'X-API-KEY':'1281ba0d-593b-4f3e-8b14-2b63e66ae00a'},
					success: function(response){
	         				var a = response.items;
			 				var index, len;
			 				for (index = 0, len = a.length; index < len; ++index) {
				 				var item = a[index];
				 					 const h1 = document.querySelector('.h1');
				 					 h1.setAttribute('style', 'font-size: 1.1em; line-height: 1em; font-weight: 700; margin-top: 1em;');
					 				 $('.fadeInElement').append('<a href="/films?id='+item.filmId+'&title='+item.nameRu+' ('+item.year+')">                <div class="creditsCardWrapper" style="width: 100px;padding-top: 0px; padding-bottom: 0px;height: 120px;">                    <img style="border-radius:5px" alt="'+item.nameRu+'" src="'+item.posterUrl+'"></div>            </a>');
							}
					}
	});
	
	$.ajax({
			 		async: true,
			 		crossDomain: true,
					url: 'https://kinopoiskapiunofficial.tech/api/v2.2/films/'+id,
					type: 'GET',
			 		headers: {'X-API-KEY':'1281ba0d-593b-4f3e-8b14-2b63e66ae00a'},
					success: function(response){
							if (response.ratingImdb == null){
								$('.entity-rating-imdb').html('-');
							} else {
								$('.entity-rating-imdb').html(response.ratingImdb);
							};
							if (response.ratingKinopoisk == null){
								$('.entity-rating-kp').html('-');
							} else {
								$('.entity-rating-kp').html(response.ratingKinopoisk);
							};	
							$(".js-title").html(response.nameRu);
							if (response.filmLength == null){
								$(".time").html('-');
							} else {
								$(".time").html(response.filmLength+' мин.');
							};
							$(".copyrightYear").html(response.year);
							$("#title").html(response.nameOriginal);
							
							if( TLT == 'null' ) {
								new_url = window.location.search + "&title=" + response.nameRu + ' (' + response.year + ')';
								window.location.href = new_url;
							};
							$(".entity-desc-description").html(response.description);
							$(".entity-desc-poster").html('<div class="entity-desc-poster-img fadeIn animated" style="background: url('+response.posterUrl+'), url("/img/nocover.png")"></div>');
							var a = response.genres;
			 				var index, len;
			 				for (index = 0, len = a.length; index < len; ++index) {
				 				var item = a[index];
				 				if (index!==0) {
					 				var title_genre = ', '+item.genre;
				 				} else {
					 				var title_genre = item.genre;
				 				};
					 				 $('#genres').append('<span class="entity-desc-link-u" itemprop="genre">'+title_genre+'</span>');
							};
							
							var a = response.countries;
			 				var index, len;
			 				for (index = 0, len = a.length; index < len; ++index) {
				 				var item = a[index];
				 				if (index!==0) {
					 				var title_genre = ', '+item.country;
				 				} else {
					 				var title_genre = item.country;
				 				};
					 				 $('#countries').append('<span class="entity-desc-link-u" itemprop="genre">'+title_genre+'</span>');
							};
							
							var age = response.ratingAgeLimits;
							var age = age.replace("age", "");
							$('.age').append(age+'+');
							
					}
	});
