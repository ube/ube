jQuery(document).ready(function($) {
  // set the focus to the first form element
  $('#bd form :input:visible:enabled:first').focus();

  // check all check boxes
  $('#checkall').click(function() {
    var status = this.checked;
    $('input.checkbox').each(function() {
      this.checked = status;
    });
  });

  // disable buttons
  $('input[type=button]').click(function() {
    $(this.name).attr('value', this.alt);
    $('input[type=button]').each(function() {
      this.disabled = true;
      this.value = 'Please wait...';
    });
    this.form.submit();
    return false;
  });

  // toggle search fields
  $('li.search a').click(function() {
    current = this.rel;
    $(current).toggle();
    $('li.search a').each(function() {
      if (this.rel != current) {
        $(this.rel).hide();
      }
    });
    return false;
  });

  // check off reclamations
  $('div.notices span').click(function() {
    $(this).addClass('strikethrough');
  });

  // select search fields
  $('.select').focus(function() {
    this.select();
  });

  // loading image
  $('.loading').click(function() {
    $(this).html('<img src="/images/loading.gif" width="13" height="13" alt="" /> Loading...');
  });
  $('.spinner').click(function() {
    $(this).html('<img src="/images/loading.gif" width="13" height="13" alt="" />');
  });

  // sessions/new
  if ($('#person_name').attr('value')) {
    $('#person_password').focus();
  }
});
