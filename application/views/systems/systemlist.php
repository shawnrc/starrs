<div class="item_container">
	<?foreach($systems as $sys) {?>
		<a href="/systems/view/<?echo $sys->get_system_name();?>/overview"><div class="system_list_box"><?echo $sys->get_system_name();?></div></a>
	<?}?>
</div>
