// Polymorfic code for list interface testing
// Coll should be an instance of a list like collection
  cnt := 0;
  Rnd.InitSequence(1, 0);
  for i := 0 to CollElCnt-1 do begin
    t := Rnd.RndI(CollElCnt);
    Coll.Add(t);
    Inc(cnt);
    Assert(_Check(Coll.Contains(t)), GetName + ': Conntains failed');
  end;

  Rnd.InitSequence(1, 0);
  Coll.ForEach(ForCollEl, nil);

  for i := 0 to CollElCnt div 2-1 do begin
    t := Rnd.RndI(CollElCnt);
    while Coll.Remove(t) do Dec(cnt);
    Assert(_Check(not Coll.Contains(t)), GetName + ': Not conntains failed');
  end;

  for i := 0 to CollElCnt div 2-1 do begin
    t := Rnd.RndI(Coll.Count);
    Coll.Put(i, CollElCnt);
    Assert(_Check(Coll.Get(i) = CollElCnt), GetName + ': Put/Get failed');
    Coll.Insert(t, CollElCnt+1);
    Assert(_Check((Coll.Get(t) = CollElCnt+1) and Coll.Contains(CollElCnt+1)), GetName + ': Conntains inserted failed');
    Coll.RemoveBy(t);
    Assert(_Check(not Coll.Contains(CollElCnt+1)), GetName + ': Not conntains removed failed');
  end;

  Assert(_Check(Coll.Count = cnt), GetName + ': Count failed');

  Coll.Clear;
  Assert(_Check(Coll.IsEmpty), GetName + ': IsEmpty failed');
  Coll.Free;